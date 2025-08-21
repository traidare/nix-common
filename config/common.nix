{
  config,
  lib,
  ...
}: {
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
  services = {
    pulseaudio.enable = lib.mkForce false;
    pipewire = {
      enable = config.services.xserver.enable;
      pulse.enable = true;
      alsa.enable = true;
    };

    logind = {
      killUserProcesses = lib.mkDefault true;
      lidSwitch = lib.mkDefault "ignore";
    };

    xserver.displayManager.lightdm.enable = lib.mkForce false;

    chrony.enable = lib.mkDefault true;

    dbus.implementation = lib.mkDefault "broker";

    userborn.enable = lib.mkDefault true;

    openssh.settings.PasswordAuthentication = false;
  };

  # TODO
  #i18n.extraLocaleSettings = {
  #  LC_TIME = "C.UTF-8";
  #};

  networking.usePredictableInterfaceNames = lib.mkDefault false;

  networking.hostName = lib.mkDefault "host";
  environment.etc."machine-id".text = "b08dfa6083e7567a1921a715000001fb"; # Whonix ID

  boot.loader = {
    timeout = lib.mkDefault 1;
    grub = {
      enable = lib.mkDefault false;
      configurationLimit = lib.mkOverride 1001 15;
    };
    systemd-boot = {
      editor = lib.mkDefault false;
      configurationLimit = lib.mkOverride 1001 15;
    };
  };

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
}
