{...}: let
  # MCU name prefix for pins
  mcuName = "host";
  mcuChip = "Linux";

  #####################################################################
  #   Raspberry Pi Host Pin Definitions
  #
  #   GPIO pins exposed via klipper_mcu linux process
  #####################################################################
  pins = {
    # Add any host GPIO pins here if needed
    # Example: gpio = mcuPin "gpiochip0/gpio17";
  };
in {
  #####################################################################
  #   Raspberry Pi Host MCU
  #
  #   Enables additional GPIO on the Pi for host-based features
  #   Uses klipper_mcu linux process for GPIO access
  #####################################################################

  "mcu ${mcuName}" = {
    serial = "/tmp/klipper_host_mcu";
    is_critical = false;
  };

  #####################################################################
  #   Host Temperature Sensor
  #####################################################################

  "temperature_sensor raspberry_pi" = {
    sensor_type = "temperature_host";
    min_temp = 10;
    max_temp = 100;
  };

  #####################################################################
  #   Export pins for use by other modules
  #
  #   Note: Host MCU firmware and service are handled by the klipper
  #   flake's host-mcu NixOS module (klipper.nixosModules.host-mcu).
  #####################################################################
  _meta = {
    inherit pins mcuName mcuChip;
  };
}
