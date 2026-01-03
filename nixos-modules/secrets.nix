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
      type = with lib.types; nullOr (either path (listOf path));
      default = null;
      description = ''
        Directories containing secret files.
        Each file will be automatically configured as a sops secret.
        If multiple directories contain files with the same name, later directories take precedence.
      '';
    };
  };

  config = lib.mkIf (cfg.directory != null) (let
    # Normalize to always get a list
    directories =
      if builtins.isList cfg.directory
      then cfg.directory
      else [cfg.directory];

    # Read all directories and merge them
    allSecrets =
      lib.foldl' (
        acc: dir:
          acc
          // (lib.mapAttrs' (name: _:
            lib.nameValuePair name {
              sopsFile = "${dir}/${name}";
              format = lib.mkDefault "binary";
              key = lib.mkDefault "";
            })
          (builtins.readDir dir))
      ) {}
      directories;
  in {
    sops.secrets = allSecrets;

    # To get proper error messages about missing secrets a dummy secret file is needed that is always present
    sops.defaultSopsFile = lib.mkIf config.sops.validateSopsFiles (
      lib.mkDefault (toString (pkgs.writeText "dummy.yaml" ""))
    );
  });
}
