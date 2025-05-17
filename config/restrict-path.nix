{
  lib,
  pkgs,
  ...
}: {
  security.sudo.extraConfig = lib.mkBefore ''
    Defaults secure_path = /run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin
  '';

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
