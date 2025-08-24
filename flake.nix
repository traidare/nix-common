{
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {config, ...}: {
        systems = ["x86_64-linux" "aarch64-linux"];
        imports = [
          ./flake-modules/staged-packages.nix
          ./lib
          ./packages
        ];

        flake.flakeModules = config.flake.lib.dirToAttrsWithDefault ./flake-modules;
        flake.nixosConfig = config.flake.lib.dirToAttrsWithDefault ./config;
        flake.nixosModules = config.flake.lib.dirToAttrsWithDefault ./nixos-modules;
      }
    );

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";

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
        flake-parts.follows = "flake-parts";
        gomod2nix.follows = "gomod2nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        stable.follows = "nixpkgs";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
}
