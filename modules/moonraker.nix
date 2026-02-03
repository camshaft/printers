{
  pkgs,
  ...
}:
{
  services.moonraker = {
    enable = true;
    address = "0.0.0.0";

    user = "moonraker";
    group = "klipper";

    analysis.enable = true;

    settings = {
      authorization = {
        trusted_clients = [
          "10.0.0.0/8"
          "127.0.0.0/8"
          "::1/128"
        ];
        cors_domains = [
          "https://my.mainsail.xyz"
          "http://my.mainsail.xyz"
          "http://*.local"
          "http://*.lan"
        ];
      };

      # File manager for gcode uploads
      file_manager = {
        enable_object_processing = "True";
      };

      # Store history about prints
      history = { };

      # Allow uploads from slicers
      octoprint_compat = { };

      zeroconf = {
        enable_ssdp = "True";
      };
    };
  };
}
