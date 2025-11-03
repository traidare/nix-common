{lib, ...}: rec {
  dirToAttrs = dir:
    lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}")) (
      builtins.readDir dir
    );

  dirToAttrsWithDefault = dir: let
    modules = dirToAttrs dir;
    default = {imports = builtins.attrValues (builtins.removeAttrs modules ["default"]);};
  in
    modules // {inherit default;};

  versionGate = newPkg: stablePkg: let
    newVersion = lib.getVersion newPkg;
    stableVersion = lib.getVersion stablePkg;
  in
    if builtins.compareVersions newVersion stableVersion > 0
    then newPkg
    else lib.warn "Package ${lib.getName newPkg} reached version >=${newVersion} on stable - stable is now used" stablePkg;

  mkNullOption = type: description:
    lib.mkOption {
      type = lib.types.nullOr type;
      default = null;
      inherit description;
    };

  mkNameFromPath = path:
    builtins.replaceStrings ["/"] ["-"] (lib.removePrefix "/" path);

  packaging = import ./packaging.nix {inherit lib;};
}
