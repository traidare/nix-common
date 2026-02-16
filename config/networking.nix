{
  config,
  lib,
  pkgs,
  ...
}: let
  quad9DNS = [
    "9.9.9.9#dns.quad9.net"
    "2620:fe::fe#dns.quad9.net"
  ];
in
  lib.mkMerge [
    # General
    {
      networking.usePredictableInterfaceNames = lib.mkDefault false;

      networking.hostName = lib.mkDefault "host";
      environment.etc."machine-id".text = "b08dfa6083e7567a1921a715000001fb"; # Whonix ID

      networking.nftables.enable = lib.mkDefault true;

      networking.nameservers = lib.mkDefault quad9DNS;
    }

    # NetworkManager
    (let
      cfg = config.networking.networkmanager;
    in {
      networking.networkmanager = {
        connectionConfig = {
          # IPv6 privacy extensions
          "ipv6.ip6-privacy" = lib.mkDefault 2;
          # Use stable UUID for DHCPv6 DUID
          "ipv6.dhcp-duid" = lib.mkDefault "stable-uuid";
        };

        # MAC address randomization
        wifi.macAddress = lib.mkDefault "random";
        ethernet.macAddress = lib.mkDefault "stable";

        settings = lib.mkMerge [
          {
            main.dns = cfg.dns;
          }
          (lib.mkIf (cfg.dns == "dnsmasq") {
            "dnsmasq" = {
              # Listen on IPv6 localhost
              "listen-address" = "::1";
            };
          })
        ];
      };

      environment.systemPackages = lib.optionals (config.networking.networkmanager.enable && config.networking.networkmanager.dns == "dnsmasq") [pkgs.dnsmasq];
    })

    # systemd-resolved
    (
      if lib.versionOlder lib.trivial.release "26"
      then {
        services.resolved = {
          domains = ["~."];
          fallbackDns = lib.mkForce config.networking.nameservers;
        };
      }
      else {
        services.resolved.settings.Resolve = {
          Domains = ["~."];
          FallbackDNS = lib.mkForce config.networking.nameservers;
        };
      }
    )
  ]
