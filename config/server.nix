{
  config,
  lib,
  ...
}: let
  cfg = config.p.server;
in {
  options.p.server = {
    enable = lib.mkEnableOption "common server configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.shellAliases = {
      nvim = lib.mkDefault "nvim-small";
    };
  };
}
