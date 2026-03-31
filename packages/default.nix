{
  config,
  inputs,
  lib,
  ...
}: {
  flake.overlays.pkgs-lib = import ./pkgs-lib;

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
      nnn.passUpstream = true;
    };

    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        overlayLibPkgs
        overlayLocalPackages
      ];
    };
  in {
    _module.args.pkgs = pkgs;
    packages = lib.p.packaging.filterExportablePackages pkgs.p.localPackages;
  };
}
