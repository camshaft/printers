{ config, pkgs, ... }:
{
  networking = {
    hostName = "voron-blue";

    # Use NetworkManager for network management (required for KlipperScreen WiFi UI)
    networkmanager = {
      enable = true;
      wifi.backend = "wpa_supplicant";
    };

    # Disable default networking (NetworkManager handles it)
    useDHCP = false;

    # CAN network configuration
    localCommands = ''
      ${pkgs.iproute2}/bin/ip link set can0 type can bitrate 1000000
      ${pkgs.iproute2}/bin/ip link set can0 txqueuelen 128
      ${pkgs.iproute2}/bin/ip link set can0 up
    '';
  };

  # Allow klipper user to manage network connections via NetworkManager
  users.users.klipper.extraGroups = [ "networkmanager" ];
}
