{
  outputs = inputs: let
    specialArgs.lib = inputs.nixpkgs.lib.extend (import ./lib/overlay.nix {inherit inputs;});
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs specialArgs;} (
      {lib, ...}: {
        systems = ["x86_64-linux" "aarch64-linux"];
        imports = [
          ./flake-modules/staged-packages.nix
          ./packages
        ];

        perSystem = {pkgs, ...}: {
          devShells.default = pkgs.mkShell {
            packages = [];
          };
        };

        flake.lib = import ./lib {inherit (inputs.nixpkgs) lib;};
        flake.flakeModules = lib.p.dirToAttrsWithDefault ./flake-modules;
        flake.nixosConfig = lib.p.dirToAttrsWithDefault ./config;
        flake.nixosModules = lib.p.dirToAttrsWithDefault ./nixos-modules;
        flake.templates.go-app = {
          path = ./templates/go-app;
          description = "Go application template using gomod2nix for deterministic builds";
        };
      }
    );

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";

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
