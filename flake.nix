{
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {
        config,
        lib,
        ...
      }: {
        systems = lib.platforms.all;
        imports = [
          ./lib
          ./packages
        ];

        flake.nixosModules = config.flake.lib.dirToAttrs ./config;
        flake.flakeModules = config.flake.lib.dirToAttrs ./flake-modules;
      }
    );

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    nix-config-helper = {
      url = "git+https://codeberg.org/traidare/nix-config-helper.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        stable.follows = "nixpkgs";
      };
    };
  };
}
