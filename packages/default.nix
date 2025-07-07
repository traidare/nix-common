{
  config,
  inputs,
  ...
}: {
  flake.overlays.pkgs-lib = import ./pkgs-lib;

  perSystem = {
    inputs',
    system,
    ...
  }: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          p = prev.p or {} // (config.flake.overlays.pkgs-lib final prev);
          lib = prev.lib.extend (
            final: prev: {p = config.flake.lib;}
          );
        })
      ];
    };
  in {
    stagedPackages = {
      inherit pkgs;
      stages = [
        {
          inputPackages = with inputs'; [[colmena "colmena"]];
        }
        {
          packages = {
            nixos-deploy = {
              path = ./pkgs/nixos-deploy;
              args = {inherit inputs';};
            };
          };
        }
      ];
    };
  };
}
