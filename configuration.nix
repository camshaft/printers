{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/display.nix
    ./modules/firewall.nix
    ./modules/gpio.nix
    ./modules/klipper.nix
    ./modules/mainsail.nix
    ./modules/moonraker.nix
    ./modules/network.nix
    ./modules/nvme.nix
    ./modules/serial.nix
    ./modules/users.nix
    ./modules/webcam.nix
  ];

  # Bootloader is configured by nixos-raspberrypi module
  boot.loader.raspberry-pi.bootloader = "kernel";

  services.openssh = {
    enable = true;
  };

  # Journald configuration - prevent logs from filling boot disk
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=10M
    MaxRetentionSec=1week
  '';

  environment.systemPackages = with pkgs; [
    curl
    dig
    inetutils
    networkmanager
    wget
  ];

  nix.settings = {
    trusted-users = [
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = "25.11";
}
