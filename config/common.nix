{
  config,
  lib,
  ...
}: let
  hasLogindSettings = lib.versionAtLeast lib.version "25.11";
in {
  documentation = {
    dev.enable = lib.mkDefault true;
    doc.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
    man = {
      mandoc.enable = config.documentation.man.enable;
      man-db.enable = lib.mkForce false;
    };
  };

  time.timeZone = lib.mkOverride 999 "CET";

  security.rtkit.enable = config.services.pipewire.enable;
  services = lib.mkMerge [
    {
      pulseaudio.enable = lib.mkForce false;
      pipewire = {
        enable = config.services.xserver.enable;
        pulse.enable = true;
        alsa.enable = true;
      };

      xserver.displayManager.lightdm.enable = lib.mkForce false;

      chrony.enable = lib.mkDefault true;

      dbus.implementation = lib.mkDefault "broker";

      # User & group managing
      userborn.enable = lib.mkDefault true;

      openssh.settings.PasswordAuthentication = false;

      gnome.gnome-keyring.enable = lib.mkOverride 950 false;
    }
    (lib.optionalAttrs hasLogindSettings {
      logind.settings.Login = {
        KillUserProcesses = lib.mkDefault true;
        HandleLidSwitch = lib.mkDefault "ignore";
      };
    })
  ];

  # TODO
  #i18n.extraLocaleSettings = {
  #  LC_TIME = "C.UTF-8";
  #};

  boot.loader = {
    timeout = lib.mkDefault 0;
    grub = {
      enable = lib.mkDefault false;
      configurationLimit = lib.mkOverride 1001 15;
    };
    systemd-boot = {
      configurationLimit = lib.mkOverride 1001 15;
      editor = lib.mkDefault false;
    };
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  programs = {
    less.envVariables.LESS = "-j10 -i -A -R";
    vim = {
      enable = lib.mkForce false;
      defaultEditor = lib.mkForce false;
    };
  };

  environment.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
    VISUAL = lib.mkDefault "nvim";
  };

  sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
}
