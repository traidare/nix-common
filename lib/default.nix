{
  lib,
  withSystem,
  ...
}: {
  flake.lib = withSystem "x86_64-linux" ({pkgs, ...}: {
    dirToAttrs = dir:
      lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}")) (
        builtins.readDir dir
      );

    versionGate = newPkg: stablePkg: let
      newVersion = lib.getVersion newPkg;
      stableVersion = lib.getVersion stablePkg;
    in
      if builtins.compareVersions newVersion stableVersion > 0
      then newPkg
      else lib.warn "Package ${lib.getName newPkg} reached version >=${newVersion} on stable - stable is now used" stablePkg;

    fromYAML = pkgs.callPackage ./from-yaml.nix {};
    toYAML = pkgs.callPackage ./to-yaml.nix {};

    mkNullOption = type: description:
      lib.mkOption {
        type = lib.types.nullOr type;
        default = null;
        inherit description;
      };
  });
}
