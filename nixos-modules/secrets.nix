{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.p.secrets;
in {
  options.p.secrets = {
    directory = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf (cfg.directory != null) {
    sops.secrets = lib.mapAttrs' (name: _:
      lib.nameValuePair (lib.removeSuffix ".${lib.last (lib.splitString "." name)}" name)
      {
        sopsFile = "${cfg.directory}/${name}";
        format = lib.mkDefault "binary";
      })
    (builtins.readDir cfg.directory);

    # To get proper error messages about missing secrets a dummy secret file is needed that is always present
    sops.defaultSopsFile = lib.mkIf config.sops.validateSopsFiles (
      lib.mkDefault (builtins.toString (pkgs.writeText "dummy.yaml" ""))
    );
  };
}
