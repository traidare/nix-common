{
  flake-parts-lib,
  inputs,
  lib,
  ...
}: let
  flakeLib = import ../lib {inherit lib;};

  handlePackages = packages: callPackage: defaultPath:
    builtins.mapAttrs (name: pkgConfig:
      if lib.isDerivation pkgConfig
      then pkgConfig
      else let
        path =
          if pkgConfig.path != null
          then pkgConfig.path
          else if defaultPath != null
          then "${defaultPath}/${name}"
          else throw "Package '${name}' has no path specified and no autoPackages.path is available";
        pkg = callPackage path (pkgConfig.args);
      in
        if pkgConfig ? versionGate && pkgConfig.versionGate != null
        then flakeLib.packaging.versionGate pkg pkgConfig.versionGate
        else pkg)
    packages;

  handleInputPackages = inputList:
    lib.foldl' (
      acc: item: let
        packages =
          if lib.isList item
          then lib.getAttrs (lib.tail item) ((lib.head item).packages)
          else item.packages;

        processedPackages =
          builtins.mapAttrs (
            name: pkg:
              if name == "default" && lib.isDerivation pkg && pkg ? pname
              then lib.nameValuePair pkg.pname pkg
              else if name == "default" && lib.isDerivation pkg && pkg ? name
              then lib.nameValuePair pkg.name pkg
              else lib.nameValuePair name pkg
          )
          packages;
      in
        acc // (builtins.listToAttrs (builtins.attrValues processedPackages))
    ) {}
    inputList;

  buildStage = prevPackages: stageConfig: basePkgs: let
    currentPkgs = basePkgs // prevPackages;
    callPackage = lib.callPackageWith currentPkgs;

    inputPkgs =
      lib.optionalAttrs (stageConfig ? inputPackages)
      (handleInputPackages stageConfig.inputPackages);

    autoPkgs =
      lib.optionalAttrs (stageConfig ? autoPackages && stageConfig.autoPackages != null)
      (flakeLib.packaging.discoverPackages (stageConfig.autoPackages // {inherit callPackage;}));

    discoverPath = stageConfig.autoPackages.path or null;
    manualPkgs =
      lib.optionalAttrs (stageConfig ? packages)
      (handlePackages stageConfig.packages callPackage discoverPath);
  in
    prevPackages // inputPkgs // autoPkgs // manualPkgs;

  buildAllStages = stages: basePkgs:
    lib.foldl' (acc: stage: buildStage acc stage basePkgs) {} stages;

  stageType = lib.types.submodule {
    options = {
      inputPackages = lib.mkOption {
        type = with lib.types; listOf (either attrs (listOf (oneOf [attrs str])));
        default = [];
        description = "Flake inputs to extract packages from";
      };

      autoPackages = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.path;
              description = "Path to auto-discover packages from";
            };
            extraArgs = lib.mkOption {
              type = lib.types.attrs;
              default = {};
              description = "Extra arguments to pass to callPackage";
            };
          };
        });
        default = null;
        description = "Auto-discover packages from filesystem";
      };

      packages = lib.mkOption {
        type = lib.types.attrsOf (lib.types.oneOf [
          lib.types.package
          (lib.types.submodule {
            options = {
              path = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = "Path to package definition";
              };
              args = lib.mkOption {
                type = lib.types.attrs;
                default = {};
                description = "Extra arguments to pass to callPackage";
              };
              versionGate = lib.mkOption {
                type = lib.types.nullOr lib.types.package;
                default = null;
                description = "Package to use for version gating";
              };
            };
          })
        ]);
        default = {};
        description = "Manually defined packages";
      };
    };
  };
in {
  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.stagedPackages;
  in {
    options.stagedPackages = lib.mkOption {
      default = {};
      type = lib.types.submodule {
        options = {
          stages = lib.mkOption {
            type = lib.types.listOf stageType;
            default = [];
            description = "List of package building stages";
          };

          pkgs = lib.mkOption {
            type = lib.types.raw;
            default = pkgs;
            description = "Base package set to build upon";
          };
        };
      };
    };

    config = let
      finalPackages = buildAllStages cfg.stages cfg.pkgs;
    in
      lib.mkIf (cfg.stages != []) {
        _module.args.pkgs = cfg.pkgs.extend (final: prev: finalPackages);
        packages = finalPackages;
      };
  });
}
