{
  config,
  inputs,
  lib,
  ...
}: {
  flake.overlays.pkgs-lib = import ./pkgs-lib;
  flake.wrappers = lib.p.packaging.discoverModules ./wrappers;

  perSystem = {
    inputs',
    system,
    ...
  }: let
    overlayLibPkgs = final: prev: {
      p = prev.p or {} // (config.flake.overlays.pkgs-lib final prev);
      lib = prev.lib.extend (
        final: prev: {p = config.flake.lib;}
      );
    };

    overlayLocalPackages = lib.p.packaging.mkLocalPackagesOverlay ./pkgs {
      nnn.upstream = p: p.nnn;
    };

    overlayWrappers = final: prev: {
      p =
        prev.p or {}
        // {
          wrappers =
            lib.mapAttrs (
              _: module:
                (inputs.nix-wrapper-modules.lib.evalModules {
                  modules = [{pkgs = final;} module];
                  specialArgs = {inherit inputs lib;};
                }).config.wrapper
            )
            config.flake.wrapperModules;
        };
    };

    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        overlayLibPkgs
        overlayLocalPackages
        overlayWrappers
      ];
    };
  in {
    _module.args.pkgs = pkgs;
    packages = lib.p.packaging.filterExportablePackages pkgs.p.localPackages;
  };
}
