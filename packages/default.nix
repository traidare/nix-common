flake @ {
  inputs,
  lib,
  withSystem,
  ...
}: {
  perSystem = {
    inputs',
    pkgs,
    system,
    ...
  }: let
    basePkgs = import inputs.nixpkgs {
      inherit system;
    };

    packages = lib.fix (
      self: let
        stage1 = lib.fix (
          self': let
            callPackage = lib.callPackageWith (pkgs // self');

            auto = lib.pipe (builtins.readDir ./packages) [
              (lib.filterAttrs (name: value: value == "directory"))
              (builtins.mapAttrs (name: _: callPackage ./packages/${name} {}))
            ];
          in
            auto
            // {
            }
        );
      in
        stage1
    );

    finalPkgs = basePkgs.extend (final: prev: packages);
  in {
    _module.args.pkgs = finalPkgs;
    inherit packages;
  };

  flake.overlays.packages = final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      {config, ...}: config.packages
    );
}
