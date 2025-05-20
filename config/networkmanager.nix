{
  config,
  lib,
  pkgs,
  ...
}: {
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
      main = {
        dns = lib.mkDefault "dnsmasq";
      };

      "dnsmasq" = {
        #"conf-file" = "/usr/share/dnsmasq/trust-anchors.conf";
        #"dnssec" = true;
        # Listen on IPv6 localhost
        "listen-address" = "::1";
      };
    };
  };

  environment.systemPackages = with pkgs;
    lib.optionals (config.networking.networkmanager.enable
      && config.networking.networkmanager.dns == "dnsmasq") [
      dnsmasq
    ];
}
