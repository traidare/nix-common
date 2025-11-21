{
  lib,
  pkgs,
  ...
}: {
  # Remove user directories from PATH environment variable
  environment.loginShellInit = let
    cleanPath = pkgs.writers.writeBash "clean_path.bash" ''
      set -euo pipefail
      readarray -d: -t paths <<< "$PATH"
      result=""
      for path in "''${paths[@]}"; do
        [[ "$path" != *"$HOME"* ]] && result="''${result:+$result:}$path"
      done
      printf '%s' "$result"
    '';
  in
    lib.mkBefore ''
      export PATH=$(${cleanPath})
    '';
}
