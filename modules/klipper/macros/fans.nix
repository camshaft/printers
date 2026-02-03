{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Nevermore Filter Fan Control
  #####################################################################

  "gcode_macro NEVERMORE_ON" = {
    description = "Turn on Nevermore filter fan";
    gcode = ''
      SET_FAN_SPEED FAN=nevermore SPEED=1.0
    '';
  };

  "gcode_macro NEVERMORE_OFF" = {
    description = "Turn off Nevermore filter fan";
    gcode = ''
      SET_FAN_SPEED FAN=nevermore SPEED=0
    '';
  };

  "gcode_macro NEVERMORE_HALF" = {
    description = "Set Nevermore filter fan to 50%";
    gcode = ''
      SET_FAN_SPEED FAN=nevermore SPEED=0.5
    '';
  };
}
