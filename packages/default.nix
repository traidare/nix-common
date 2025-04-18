flake @ {
  inputs,
  lib,
  withSystem,
  ...
}: {
  perSystem = {
    inputs',
    pkgs,
    system,
    ...
  }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;

      overlays = [
      ];
    };

    packages = lib.fix (
      self: let
        # packages in $FLAKE/packages, callPackage'd automatically
        stage1 = lib.fix (
          self': let
            callPackage = lib.callPackageWith (pkgs // self');
            #callPackage = lib.callPackageWith <| pkgs // self';

            auto = lib.pipe (builtins.readDir ./.) [
              (lib.filterAttrs (name: value: value == "directory"))
              (builtins.mapAttrs (name: _: callPackage ./${name} {}))
            ];
          in
            auto
            // {
              # preventing infrec
              #sioyek-fhs = callPackage ./yazi {inherit (pkgs) sioyek qt6 installShellFiles;};
            }
        );
      in
        stage1
      #  # wrapper-manager packages
      #  stage2 =
      #    stage1
      #    // (inputs.wrapper-manager.lib {
      #      pkgs = pkgs // stage1;
      #      modules = lib.pipe (builtins.readDir ../modules/wrapper-manager) [
      #        (lib.filterAttrs (name: value: value == "directory"))
      #        builtins.attrNames
      #        (map (n: ../modules/wrapper-manager/${n}))
      #      ];
      #      specialArgs = {
      #        inherit inputs';
      #      };
      #    })
      #    .config
      #    .build
      #    .packages;
      #in
      #  stage2
    );
  };

  flake.overlays.packages = final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      {config, ...}: config.packages
    );
}
