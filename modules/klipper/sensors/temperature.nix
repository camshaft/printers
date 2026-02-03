{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pins = config.pins;
in {
  #####################################################################
  #   Temperature Sensors
  #####################################################################

  #####################################################################
  #   Chamber Temperature - Leviathan Extension TH4
  #####################################################################
  
  "temperature_sensor chamber" = {
    sensor_type = "ATC Semitec 104NT-4-R025H42G";
    sensor_pin = pins.leviathan_ext.thermistor.th4;
    pullup_resistor = 2200;
    min_temp = 0;
    max_temp = 100;
    gcode_id = "chamber";
  };

  #####################################################################
  #   Leviathan Board Temperature
  #####################################################################
  
  "temperature_sensor leviathan" = {
    sensor_type = "temperature_mcu";
    min_temp = 0;
    max_temp = 100;
  };
}
