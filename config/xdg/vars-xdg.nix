system: let
  XDG_CACHE_HOME = "$HOME/.cache";
  XDG_CONFIG_HOME = "$HOME/.config";
  XDG_DATA_HOME = "$HOME/.local/share";
  XDG_DESKTOP_DIR = "$HOME";
  XDG_MUSIC_DIR = "$HOME/Music";
  XDG_PICTURES_DIR = "$HOME/Downloads";
  XDG_PUBLICSHARE_DIR = "$HOME";
  XDG_SCREENSHOTS_DIR = "$HOME/screenshots";
  XDG_STATE_HOME = "$HOME/.local/state";
  XDG_TEMPLATES_DIR = "$HOME";
  XDG_VIDEOS_DIR = "$HOME/Downloads";
in {
  apps = {
    PYTHONSTARTUP =
      if system == "nixos"
      then "/etc/pythonrc"
      else "${XDG_CONFIG_HOME}/python/pythonrc";
    PYTHONPYCACHEPREFIX = "${XDG_CACHE_HOME}/python";
    PYTHONUSERBASE = "${XDG_DATA_HOME}/python";

    ANDROID_HOME = "${XDG_DATA_HOME}/android";
    ANDROID_USER_HOME = "${XDG_DATA_HOME}/android";
    CABAL_DIR = "${XDG_DATA_HOME}/cabal";
    CARGO_HOME = "$(mktemp -d)";
    CUDA_CACHE_PATH = "${XDG_CACHE_HOME}/nv";
    DOCKER_CONFIG = "${XDG_CONFIG_HOME}/docker";
    ERRFILE = "${XDG_CACHE_HOME}/X11/xsession-errors";
    GNUPGHOME = "${XDG_DATA_HOME}/gnupg";
    GOCACHE = "${XDG_CACHE_HOME}/go/build";
    GOMODCACHE = "${XDG_CACHE_HOME}/go/mod";
    GOPATH = "${XDG_DATA_HOME}/go";
    GRADLE_USER_HOME = "${XDG_DATA_HOME}/gradle";
    GUILE_HISTORY = "${XDG_STATE_HOME}/guile_history";
    HISTFILE = "${XDG_DATA_HOME}/bash/history";
    INPUTRC = "${XDG_CONFIG_HOME}/inputrc";
    IPYTHONDIR = "${XDG_CONFIG_HOME}/ipython";
    JULIA_DEPOT_PATH = "${XDG_DATA_HOME}/julia:$JULIA_DEPOT_PATH";
    JUPYTER_CONFIG_DIR = "${XDG_CONFIG_HOME}/jupyter";
    KDEHOME = "${XDG_CONFIG_HOME}/kde";
    KERAS_HOME = "${XDG_STATE_HOME}/keras";
    LESSHISTFILE = "${XDG_DATA_HOME}/less/history";
    LYNX_CFG = "${XDG_CONFIG_HOME}/lynx/lynx.cfg";
    LYNX_CFG_PATH = "${XDG_CONFIG_HOME}/lynx/lynx.cfg";
    LYNX_LSS = "${XDG_CONFIG_HOME}/lynx/lynx.lss";
    NODE_REPL_HISTORY = "${XDG_DATA_HOME}/node_repl_history";
    NPM_CONFIG_CACHE = "${XDG_CACHE_HOME}/npm";
    NPM_CONFIG_USERCONFIG = "${XDG_CONFIG_HOME}/npm/npmrc";
    NUGET_PACKAGES = "${XDG_CACHE_HOME}/NuGetPackages";
    PLATFORMIO_CORE_DIR = "${XDG_DATA_HOME}/platformio";
    SQLITE_HISTORY = "${XDG_CACHE_HOME}/sqlite_history";
    STEPPATH = "${XDG_DATA_HOME}/step";
    TERMINFO = "${XDG_DATA_HOME}/terminfo";
    TERMINFO_DIRS = "${XDG_DATA_HOME}/terminfo:/usr/share/terminfo";
    TEXMFCONFIG = "${XDG_CONFIG_HOME}/texlive/texmf-config";
    TEXMFHOME = "${XDG_DATA_HOME}/texlive/texmf";
    TEXMFVAR = "${XDG_CACHE_HOME}/texlive/texmf-var";
    WGETRC = "${XDG_CONFIG_HOME}/wgetrc";
    WINEPREFIX = "${XDG_DATA_HOME}/wine";
    XCOMPOSECACHE = "${XDG_CACHE_HOME}/X11/xcompose";
    XCOMPOSEFILE = "/etc/X11/XCompose";
  };

  xdg = {
    inherit
      XDG_CACHE_HOME
      XDG_CONFIG_HOME
      XDG_DATA_HOME
      XDG_DESKTOP_DIR
      XDG_MUSIC_DIR
      XDG_PICTURES_DIR
      XDG_PUBLICSHARE_DIR
      XDG_SCREENSHOTS_DIR
      XDG_STATE_HOME
      XDG_TEMPLATES_DIR
      XDG_VIDEOS_DIR
      ;
  };
}
