{
  config,
  flake-parts-lib,
  inputs,
  lib,
  ...
}: let
  inherit (lib) types mkOption;
  inherit (config.flake.lib.packaging) discoverWrapperModules discoverPackages;

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
        then config.flake.lib.versionGate pkg pkgConfig.versionGate
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

  handleWrapperManager = {
    moduleDir ? null,
    modules ? [],
    specialArgs ? {},
  }: pkgs:
    (inputs.wrapper-manager.lib {
      modules = (discoverWrapperModules moduleDir) ++ modules;
      inherit pkgs specialArgs;
    }).config.build.packages;

  buildStage = prevPackages: stageConfig: basePkgs: let
    currentPkgs = basePkgs // prevPackages;
    callPackage = lib.callPackageWith currentPkgs;

    inputPkgs =
      lib.optionalAttrs (stageConfig ? inputPackages)
      (handleInputPackages stageConfig.inputPackages);

    autoPkgs =
      lib.optionalAttrs (stageConfig ? autoPackages && stageConfig.autoPackages != null)
      (discoverPackages (stageConfig.autoPackages // {inherit callPackage;}));

    discoverPath = stageConfig.autoPackages.path or null;
    manualPkgs =
      lib.optionalAttrs (stageConfig ? packages)
      (handlePackages stageConfig.packages callPackage discoverPath);

    wrapperPkgs =
      lib.optionalAttrs (stageConfig ? wrapperManager && stageConfig.wrapperManager != null)
      (handleWrapperManager stageConfig.wrapperManager currentPkgs);
  in
    prevPackages // inputPkgs // autoPkgs // manualPkgs // wrapperPkgs;

  buildAllStages = stages: basePkgs:
    lib.foldl' (acc: stage: buildStage acc stage basePkgs) {} stages;

  stageType = types.submodule {
    options = {
      inputPackages = mkOption {
        type = types.listOf (types.either types.attrs (types.listOf (types.oneOf [types.attrs types.str])));
        default = [];
        description = "Flake inputs to extract packages from";
      };

      autoPackages = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            path = mkOption {
              type = types.path;
              description = "Path to auto-discover packages from";
            };
            extraArgs = mkOption {
              type = types.attrs;
              default = {};
              description = "Extra arguments to pass to callPackage";
            };
          };
        });
        default = null;
        description = "Auto-discover packages from filesystem";
      };

      packages = mkOption {
        type = types.attrsOf (types.oneOf [
          types.package
          (types.submodule {
            options = {
              path = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Path to package definition";
              };
              args = mkOption {
                type = types.attrs;
                default = {};
                description = "Extra arguments to pass to callPackage";
              };
              versionGate = mkOption {
                type = types.nullOr types.package;
                default = null;
                description = "Package to use for version gating";
              };
            };
          })
        ]);
        default = {};
        description = "Manually defined packages";
      };

      wrapperManager = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            moduleDir = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "Directory containing wrapper manager modules";
            };
            modules = mkOption {
              type = types.listOf types.path;
              default = [];
              description = "Additional wrapper manager modules";
            };
            specialArgs = mkOption {
              type = types.attrs;
              default = {};
              description = "Special arguments for wrapper manager";
            };
          };
        });
        default = null;
        description = "Wrapper manager configuration";
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
      type = types.submodule {
        options = {
          stages = mkOption {
            type = types.listOf stageType;
            default = [];
            description = "List of package building stages";
          };

          pkgs = mkOption {
            type = types.raw;
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
