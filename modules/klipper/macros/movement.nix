{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Movement Helper Macros
  #####################################################################

  "gcode_macro FRONT" = {
    description = "Move toolhead to front center for maintenance";
    gcode = ''
      _ENSURE_HOMED
      G90
      G0 X${toString config.dimensions.home_x} Y10 Z${toString config.movement.travel_clearance} F${toString config.speeds.travel}
    '';
  };

  "gcode_macro CENTER" = {
    description = "Move toolhead to center of bed";
    gcode = ''
      _ENSURE_HOMED
      G90
      G0 X${toString config.dimensions.home_x} Y${toString config.dimensions.home_y} Z${toString config.movement.travel_clearance} F${toString config.speeds.travel}
    '';
  };

  "gcode_macro REAR" = {
    description = "Move toolhead to rear center";
    gcode = ''
      _ENSURE_HOMED
      G90
      G0 X${toString config.dimensions.home_x} Y${toString (config.dimensions.bed_size - 10)} Z${toString config.movement.travel_clearance} F${toString config.speeds.travel}
    '';
  };

  "gcode_macro PARK_NOZZLE" = {
    description = "Park the nozzle at the rear of the bed";
    gcode = ''
      _ENSURE_HOMED
      G90
      G0 X${toString config.dimensions.home_x} Y${toString (config.dimensions.bed_size - 5)} Z${toString config.movement.travel_clearance} F${toString config.speeds.travel}
    '';
  };

  "gcode_macro PRIME_LINE" = {
    description = "Prime the nozzle with a line";
    gcode = ''
      G92 E0
      G90
      G0 X5 Y5 Z0.3 F${toString config.speeds.travel}
      G1 X100 E${toString config.purge.prime_length} F${toString config.purge.prime_speed}
      G1 X150 F${toString config.speeds.travel}
      G92 E0
    '';
  };
}
