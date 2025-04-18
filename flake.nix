{
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {
        lib,
        config,
        ...
      }: {
        imports = [
          ./lib
          ./packages
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake.flakeModules.default = ./lib;
        flake.nixosModules = config.flake.lib.dirToAttrs ./modules/nixos;
      }
    );

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
}
