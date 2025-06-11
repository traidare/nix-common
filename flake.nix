{
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {
        config,
        lib,
        ...
      }: {
        imports = [
          ./lib
          ./packages
        ];

        systems = ["x86_64-linux"];

        flake.nixosModules = config.flake.lib.dirToAttrs ./config;
      }
    );

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
}
