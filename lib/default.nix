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
