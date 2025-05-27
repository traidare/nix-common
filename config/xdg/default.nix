{config, ...}: let
  varsXDG = import ./vars-xdg.nix "nixos";
  varsDNT = import ./vars-donottrack.nix;

  env = config.environment.sessionVariables;
in {
  environment.sessionVariables = varsXDG.xdg // varsXDG.apps // varsDNT;

  environment.etc = {
    npmrc.text = ''
      prefix=${env.XDG_DATA_HOME}/npm
      cache=${env.XDG_CACHE_HOME}/npm
      init-module=${env.XDG_CONFIG_HOME}/npm/config/npm-init.js
      logs-dir=${env.XDG_STATE_HOME}/npm/logs
    '';

    pythonrc.text = builtins.readFile ./files/pythonrc.py;
  };
}
