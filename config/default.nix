{
  config,
  lib,
  ...
}: {
  imports = [
    ./common-vars
    ./fhs.nix
    ./nix-conf.nix
    ./packages.nix
    ./restrict-path.nix
    ./shell.nix
  ];

  documentation = {
    dev.enable = lib.mkDefault true;
    doc.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
    man = {
      mandoc.enable = lib.mkDefault true;
      man-db.enable = lib.mkDefault false;
    };
  };

  time.timeZone = lib.mkDefault "CET";

  security.sudo = {
    extraConfig = ''
      Defaults timestamp_timeout=30
      Defaults lecture=never
      Defaults passprompt="[31m SUDO: password for %p@%h, running as %U:[0m "
    '';
  };

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

    xserver.displayManager.gdm.enable = lib.mkForce false;
    xserver.displayManager.lightdm.enable = lib.mkForce false;

    chrony.enable = lib.mkDefault true;

    dbus.implementation = lib.mkDefault "broker";
  };

  # TODO
  #i18n.extraLocaleSettings = {
  #  LC_TIME = "C.UTF-8";
  #};

  networking = {
    hostName = lib.mkDefault "host";
    # "b08dfa6083e7567a1921a715000001fb"; # Whonix ID # TODO
  };

  boot.loader = {
    timeout = lib.mkDefault 1;
    grub.enable = lib.mkDefault false;
    systemd-boot = {
      editor = lib.mkDefault false;
      configurationLimit = lib.mkDefault 50;
    };
  };

  programs.less.envVariables.LESS = "-j10 -i -A -R";
}
