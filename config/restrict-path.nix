{
  lib,
  pkgs,
  ...
}: {
  # Remove user directories from PATH environment variable
  environment.loginShellInit = let
    cleanPath = pkgs.writers.writeNu "clean_path.nu" ''
      $env.PATH
      | split row ':'
      | where { |path| not ($path | str contains $env.HOME) }
      | str join ':'
    '';
  in
    lib.mkBefore ''
      export PATH=$(${cleanPath})
    '';
}
