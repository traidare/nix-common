flake @ {
  config,
  inputs,
  lib,
  withSystem,
  ...
}: {
  perSystem = {
    inputs',
    system,
    ...
  }: let
    basePkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          lib = prev.lib.extend (
            final: prev: {
              p = config.flake.lib;
            }
          );
        })
      ];
    };

    packages = lib.fix (
      self: let
        stage1 = lib.fix (
          self': let
            pkgs = basePkgs;
            callPackage = lib.callPackageWith (pkgs // self');

            auto = lib.pipe (builtins.readDir ./packages) [
              (lib.filterAttrs (name: value: value == "directory"))
              (builtins.mapAttrs (name: _: callPackage ./packages/${name} {}))
            ];
          in
            auto
            // {
              nixos-deploy = callPackage ./packages/nixos-deploy {inherit inputs';};
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

  flake.overlays.default = final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      {config, ...}: config.packages
    );
}
