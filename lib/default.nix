{
  inputs,
  lib,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
in {
  flake.lib = {
    dirToAttrs = dir:
      lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}")) (
        builtins.readDir dir
      );

    versionGate = newPkg: stablePkg: let
      newVersion = lib.getVersion newPkg;
      stableVersion = lib.getVersion stablePkg;
    in
      if builtins.compareVersions newVersion stableVersion > 0
      then newPkg
      else lib.warn "Package ${lib.getName newPkg} reached version ${newVersion} at stable" stablePkg;

    fromYAML = e: let
      jsonOutputDrv = pkgs.runCommandLocal "from-yaml" {
        nativeBuildInputs = with pkgs; [yq-go];
      } "yq -o json - <<<'${e}' > $out";
    in
      builtins.fromJSON (builtins.readFile jsonOutputDrv);

    mkGraphicalService = lib.recursiveUpdate {
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      wantedBy = ["graphical-session.target"];
    };
  };
}
