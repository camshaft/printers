{config, ...}: {
  services.mainsail = {
    enable = true;

    hostName = "${config.networking.hostName}.lan";
  };
}
