{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  
  # MCU name prefix for pins
  mcuName = "host";
  mcuChip = "Linux";

  # Helper to create MCU-prefixed pins
  mcuPin = p: "${mcuName}:${p}";

  #####################################################################
  #   Raspberry Pi Host Pin Definitions
  #   
  #   GPIO pins exposed via klipper_mcu linux process
  #####################################################################
  pins = {
    # Add any host GPIO pins here if needed
    # Example: gpio = mcuPin "gpiochip0/gpio17";
  };

  #####################################################################
  #   Raspberry Pi Host MCU Firmware Configuration
  #   
  #   Linux process MCU for host GPIO access (no USB, runs as process)
  #####################################################################
  firmware = {
    klipper = {
      CONFIG_LOW_LEVEL_OPTIONS = "y";
      CONFIG_MACH_LINUX = "y";
    };
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
  #   Export pins and firmware config for use by other modules
  #####################################################################
  _meta = {
    inherit pins firmware mcuName mcuChip;
  };
}
