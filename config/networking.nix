{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  # General
  {
    networking.usePredictableInterfaceNames = lib.mkDefault false;

    networking.hostName = lib.mkDefault "host";
    environment.etc."machine-id".text = "b08dfa6083e7567a1921a715000001fb"; # Whonix ID

    networking.nftables.enable = lib.mkDefault true;
  }

  # NetworkManager
  {
    networking.networkmanager = {
      dns = lib.mkDefault "dnsmasq";

      connectionConfig = {
        # IPv6 privacy extensions
        "ipv6.ip6-privacy" = lib.mkDefault 2;
        # Use stable UUID for DHCPv6 DUID
        "ipv6.dhcp-duid" = lib.mkDefault "stable-uuid";
      };

      # MAC address randomization
      wifi.macAddress = lib.mkDefault "random";
      ethernet.macAddress = lib.mkDefault "stable";

      settings = {
        main.dns = lib.mkDefault "dnsmasq";

        "dnsmasq" = {
          #"conf-file" = "/usr/share/dnsmasq/trust-anchors.conf";
          #"dnssec" = true;
          # Listen on IPv6 localhost
          "listen-address" = "::1";
        };
      };
    };

    environment.systemPackages = lib.optionals (config.networking.networkmanager.enable && config.networking.networkmanager.dns == "dnsmasq") [pkgs.dnsmasq];
  }

  # systemd-resolved
  (
    if lib.versionOlder lib.trivial.release "26"
    then {
      services.resolved.fallbackDns = [
        "9.9.9.9"
        "2620:fe::fe"
      ];
    }
    else {
      services.resolved.settings.Resolve.FallbackDNS = [
        "9.9.9.9"
        "2620:fe::fe"
      ];
    }
  )
]
