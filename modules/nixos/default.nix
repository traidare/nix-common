{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./fhs.nix
    ./xdg
  ];

  environment = {
    defaultPackages = [];

    sessionVariables = {
      GOPROXY = lib.mkDefault "direct";
    };

    shellAliases = {
      ls = lib.mkForce "ls -F --sort=extension";
      ll = lib.mkForce "ls -lh";
      l = lib.mkForce "ls -lhA";
    };
  };

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
      Defaults secure_path = /run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin
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

  # Use the latest Linux kernel release
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  programs = {
    less.envVariables.LESS = "-j10 -i -A -R";
    command-not-found.enable = false;
  };
}
