{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}: {
  options.nixos-deploy = {
    system = lib.mkOption {
      type = lib.types.str;
      default = "x86_64-linux";
    };

    commonModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
      description = "Common modules to include in all NixOS configurations";
    };

    mkSpecialArgs = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      default = system: {};
      description = "Function to generate specialArgs for all NixOS configurations";
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          modules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [];
            description = "Host-specific modules";
          };

          system = lib.mkOption {
            type = lib.types.str;
            default = config.nixos-deploy.system;
            description = "System architecture for this host";
          };

          colmena = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options = {
                targetHost = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "The target host for Colmena Nodes";
                };
                targetUser = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                  description = "The target user for Colmena Nodes";
                };
              };
            });
            default = null;
          };
        };
      }));
      default = {};
    };
  };

  config = let
    cfg = config.nixos-deploy;

    mkNixpkgs = system:
      withSystem system ({pkgs, ...}: pkgs);

    mkNixos = system: name: extraModules:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs =
          (cfg.mkSpecialArgs system)
          // {
            hostName = name;
          };
        pkgs = mkNixpkgs system;
        modules = cfg.commonModules ++ extraModules;
      };
  in
    lib.mkIf (cfg.hosts != {}) {
      flake.nixosConfigurations =
        lib.mapAttrs (
          name: hostCfg:
            mkNixos hostCfg.system name hostCfg.modules
        )
        cfg.hosts;

      flake.colmenaHive = lib.mkIf (inputs ? colmena) (inputs.colmena.lib.makeHive config.flake.colmena);
      flake.colmena =
        {
          meta = {
            nixpkgs = mkNixpkgs cfg.system;
            specialArgs =
              cfg.mkSpecialArgs cfg.system
              // {imports = cfg.commonModules;};
            allowApplyAll = false;
          };
        }
        // (builtins.mapAttrs (name: hostCfg: {
          imports =
            (self.nixosConfigurations.${name})._module.args.modules
            ++ [
              {
                deployment = hostCfg.colmena;
              }
            ];
        }) (lib.filterAttrs (name: hostCfg: hostCfg.colmena != null) cfg.hosts));
    };
}
