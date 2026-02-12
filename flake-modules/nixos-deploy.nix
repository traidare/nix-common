{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}: let
  cfg = config.nixos-deploy;

  colmenaSubmodule = lib.types.nullOr (lib.types.submodule {
    options = {
      targetHost = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "The target host for Colmena deployment";
      };
      targetUser = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "The target user for Colmena deployment";
      };
    };
  });
in {
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
      type = lib.types.attrsOf (lib.types.submodule ({
        name,
        config,
        ...
      }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
          };

          modules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [];
          };

          system = lib.mkOption {
            type = lib.types.str;
            default = cfg.system;
          };

          colmena = lib.mkOption {
            type = colmenaSubmodule;
            default = null;
          };

          vm = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule (vmArgs: {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "${config.name}-vm";
                };

                modules = lib.mkOption {
                  type = lib.types.listOf lib.types.deferredModule;
                  default = [];
                  description = "Additional modules for VM variant (merged with host modules)";
                };

                system = lib.mkOption {
                  type = lib.types.str;
                  default = config.system;
                };

                colmena = lib.mkOption {
                  type = colmenaSubmodule;
                  default = null;
                };
              };
            }));
            default = null;
            description = "If set, generates a VM variant with QEMU guest support";
          };
        };
      }));
      default = {};
    };
  };

  config = let
    mkPkgs = system:
      withSystem system ({pkgs, ...}: pkgs);

    # Generate specialArgs for a given system and hostName
    mkSpecialArgsFor = system: hostName:
      (cfg.mkSpecialArgs system)
      // {
        inherit hostName;
      };

    mkNixos = system: name: extraModules:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = mkSpecialArgsFor system name;
        pkgs = mkPkgs system;
        modules = cfg.commonModules ++ extraModules;
      };

    # Build host config and optionally VM variant
    mkHostConfigs = name: hostCfg: let
      hostConfig = mkNixos hostCfg.system hostCfg.name hostCfg.modules;

      vmModules =
        hostCfg.modules
        ++ [
          {
            services.qemuGuest.enable = true;
            services.spice-vdagentd.enable = true;
          }
        ]
        ++ (hostCfg.vm.modules or []);
      vmConfig = mkNixos hostCfg.vm.system hostCfg.vm.name vmModules;
    in
      {${hostCfg.name} = hostConfig;}
      // lib.optionalAttrs (hostCfg.vm != null) {${hostCfg.vm.name} = vmConfig;};

    # Collect all nixosConfigurations (hosts + VMs)
    allConfigs = lib.pipe cfg.hosts [
      (lib.mapAttrsToList mkHostConfigs)
      (builtins.foldl' (a: b: a // b) {})
    ];

    # Collect colmena hosts
    colmenaHosts = lib.pipe cfg.hosts [
      (lib.mapAttrsToList (name: hostCfg:
        # Set targetHost default to the host name if not specified
          (lib.optionalAttrs (hostCfg.colmena != null) {
            ${hostCfg.name} =
              hostCfg.colmena
              // {
                targetHost =
                  if hostCfg.colmena.targetHost != null
                  then hostCfg.colmena.targetHost
                  else hostCfg.name;
              };
          })
          // (lib.optionalAttrs (hostCfg.vm != null && hostCfg.vm.colmena != null) {
            ${hostCfg.vm.name} =
              hostCfg.vm.colmena
              // {
                targetHost =
                  if hostCfg.vm.colmena.targetHost != null
                  then hostCfg.vm.colmena.targetHost
                  else hostCfg.vm.name;
              };
          })))
      (lib.foldl' lib.mergeAttrs {})
    ];
  in
    lib.mkIf (cfg.hosts != {}) {
      flake.nixosConfigurations = allConfigs;

      flake.colmenaHive = lib.mkIf (inputs ? colmena) (inputs.colmena.lib.makeHive config.flake.colmena);
      flake.colmena =
        {
          meta = {
            nixpkgs = mkPkgs cfg.system;
            specialArgs = cfg.mkSpecialArgs cfg.system;
            allowApplyAll = false;
          };
        }
        // (builtins.mapAttrs (name: colmenaCfg: let
            hostSystem = self.nixosConfigurations.${name}.pkgs.system;
          in {
            imports =
              (self.nixosConfigurations.${name})._module.args.modules
              ++ [
                {
                  deployment = colmenaCfg;
                  _module.args = mkSpecialArgsFor hostSystem name;
                }
              ];
          })
          colmenaHosts);
    };
}
