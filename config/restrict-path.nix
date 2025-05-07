{lib, ...}: {
  security.sudo.extraConfig = lib.mkBefore ''
    Defaults secure_path = /run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin
  '';

  # Remove user directories from PATH environment variable
  environment.loginShellInit = lib.mkBefore ''
    clean_path() {
      PATH_ORIG="$PATH"
      PATH_NEW=""
      OLDIFS="$IFS"
      IFS=":"

      for p in $PATH_ORIG; do
          if ! echo "$p" | grep -q "$HOME"; then
              [ -z "$PATH_NEW" ] && PATH_NEW="$p" || PATH_NEW="$PATH_NEW:$p"
          fi
      done

      IFS="$OLDIFS"
      export PATH="$PATH_NEW"
      unset PATH_ORIG PATH_NEW OLDIFS
    }
    clean_path
    unset -f clean_path
  '';
}
