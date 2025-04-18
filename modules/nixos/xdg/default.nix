{config, ...}: let
  vars = import ./vars.nix "nixos";
  env = config.environment.sessionVariables;
in {
  environment.sessionVariables = vars.env // vars.xdg_env;

  environment.etc = {
    npmrc.text = ''
      prefix=${env.XDG_DATA_HOME}/npm
      cache=${env.XDG_CACHE_HOME}/npm
      init-module=${env.XDG_CONFIG_HOME}/npm/config/npm-init.js
      logs-dir=${env.XDG_STATE_HOME}/npm/logs
    '';

    pythonrc.text = builtins.readFile ./pythonrc;
  };
}
