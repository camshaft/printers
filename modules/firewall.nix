{ pkgs, ... }:
{
  networking.firewall = {
    allowedTCPPorts = [
      80 # HTTP
    ];
    allowedUDPPorts = [
      5353 # mDNS for printer discovery
    ];
  };
}
