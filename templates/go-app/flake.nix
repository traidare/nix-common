{
  outputs = inputs: let
    projectName = "myproject";
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({...}: {
      systems = inputs.nixpkgs.lib.platforms.all;

      perSystem = {
        config,
        inputs',
        pkgs,
        ...
      }: {
        packages = {
          ${projectName} = inputs'.gomod2nix.legacyPackages.buildGoApplication {
            pname = projectName;
            version = "0.1.0";

            inherit (pkgs) go;
            modules = ./gomod2nix.toml;
            src = ./.;

            #buildInputs = [];
          };
          default = config.packages.${projectName};
        };

        devShells.default = pkgs.mkShell {
          packages = [
            inputs'.gomod2nix.legacyPackages.gomod2nix
          ];
        };
      };
    });

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
