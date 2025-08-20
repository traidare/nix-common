{
  config,
  lib,
  ...
}: {
  security.sudo = {
    execWheelOnly = true;

    extraConfig = lib.mkBefore ''
      Defaults secure_path = /run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin

      Defaults timestamp_timeout=30
      Defaults lecture=never
      Defaults passprompt="[31m Sudo: Password for '%p@%h', running as '%U:[0m' "
    '';
  };

  assertions = let
    wheelUsers = builtins.attrNames (lib.filterAttrs (name: user: builtins.elem "wheel" (user.extraGroups or [])) config.users.users);
    validUsers = users: users == [] || users == ["root"] || builtins.all (user: builtins.elem user wheelUsers) users;
    validGroups = groups: groups == [] || groups == ["wheel"];
    validUserGroups =
      builtins.all (
        r: validUsers (r.users or []) && validGroups (r.groups or [])
      )
      config.security.sudo.extraRules;
  in [
    {
      assertion = config.security.sudo.execWheelOnly -> validUserGroups;
      message = "Some definitions in `security.sudo.extraRules` refer to users other than 'root' or users not in the 'wheel' group, or groups other than 'wheel'. Disable `config.security.sudo.execWheelOnly`, or adjust the rules.";
    }
  ];
}
