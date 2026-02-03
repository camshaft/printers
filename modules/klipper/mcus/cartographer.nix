{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pinLib = import ../lib/pins.nix { inherit lib; };
  inherit (pinLib) mkPins;

  #####################################################################
  #   Cartographer V3 Pin Definitions
  #####################################################################
  pinDefs = mkPins "cartographer" {
    # ADXL345 accelerometer
    accel = {
      cs = { pin = "PA3"; alias = "ACCEL_CS"; };
      cs_v4 = "PA0"; # V4 uses different CS pin (no alias)
    };
    spi_bus = "spi1";
  };

  # Extract pins and aliases from the generated definitions
  inherit (pinDefs) pins raw aliases;

  #####################################################################
  #   Cartographer Firmware Configuration
  #   
  #   Cartographer uses manufacturer firmware - updates via their docs:
  #   https://docs.cartographer3d.com/
  #####################################################################
  firmware = {};

in {
  #####################################################################
  #   MCU: Cartographer V3 Probe
  #   
  #   Probe controller on CANBUS
  #####################################################################
  
  "mcu cartographer" = {
    canbus_uuid = config.mcus.cartographer.canbus_uuid;
    is_critical = false;
  };

  #####################################################################
  #   Cartographer Temperature Sensor
  #####################################################################
  
  "temperature_sensor cartographer" = {
    sensor_type = "temperature_mcu";
    sensor_mcu = "cartographer";
    min_temp = 5;
    max_temp = 105;
  };

  #####################################################################
  #   Accelerometer (ADXL345 on Cartographer)
  #####################################################################
  
  adxl345 = {
    cs_pin = pins.accel.cs;
    spi_bus = pins.spi_bus;
  };

  #####################################################################
  #   Export pins and firmware for use by other modules
  #####################################################################
  _meta = {
    inherit pins firmware aliases;
    rawPins = raw;
    virtual_endstop = "probe:z_virtual_endstop";
  };
}
