{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Homing & Leveling Macros
  #####################################################################

  "gcode_macro G32" = {
    description = "Home all axes and perform quad gantry leveling";
    gcode = ''
      SAVE_GCODE_STATE NAME=STATE_G32
      G90
      G28
      QUAD_GANTRY_LEVEL
      G28 Z
      G0 X${toString config.dimensions.home_x} Y${toString config.dimensions.home_y} Z${toString config.movement.travel_clearance} F${toString config.speeds.travel}
      RESTORE_GCODE_STATE NAME=STATE_G32
    '';
  };

  "gcode_macro CHOME" = {
    description = "Conditional home - only homes if not already homed";
    gcode = ''
      {% if "xyz" not in printer.toolhead.homed_axes %}
        G28
      {% endif %}
    '';
  };

  "gcode_macro _ENSURE_HOMED" = {
    description = "Ensure all axes are homed before proceeding";
    gcode = ''
      {% if "xyz" not in printer.toolhead.homed_axes %}
        G28
      {% endif %}
    '';
  };
}
