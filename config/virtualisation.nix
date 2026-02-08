{
  config,
  lib,
  pkgs,
  ...
}: let
  docker = config.virtualisation.docker;
  dockerRL = config.virtualisation.docker.rootless;
  podman = config.virtualisation.podman;
in {
  environment.systemPackages = with pkgs;
    lib.optionals (docker.enable || podman.enable)
    [
      containerd
      docker-compose
      passt
      podman-compose
      slirp4netns
    ];

  virtualisation.podman = {
    dockerCompat = lib.mkIf (!docker.enable && !dockerRL.enable) true;
    #dockerSocket.enable = lib.mkIf (!docker.enable) true;

    # Required for containers under podman-compose to be able to talk to each other.
    defaultNetwork.settings.dns_enabled = true;

    autoPrune = {
      enable = lib.mkDefault true;
      flags = ["--all"];
      dates = lib.mkDefault "monthly";
    };
  };

  virtualisation.docker.rootless = {
    setSocketVariable = lib.mkDefault true;
  };
  virtualisation.docker = {
    storageDriver = lib.mkIf (config.fileSystems ? "/" && config.fileSystems."/".fsType == "btrfs") "btrfs";
  };

  virtualisation.containers = {
    enable = true;
    storage.settings.storage = {
      graphroot = lib.mkDefault "/var/lib/containers/storage";
      runroot = lib.mkDefault "/run/containers/storage";
      driver = lib.mkIf (config.fileSystems ? "/" && config.fileSystems."/".fsType == "btrfs") "btrfs";
    };
  };
}
