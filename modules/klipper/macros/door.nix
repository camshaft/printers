{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Door Sensor Handlers (Custom Chamber MCU)
  #   
  #   Opening the door turns lights white for visibility.
  #   Closing the door restores the previous light state.
  #   Printing is NOT paused when the door opens.
  #####################################################################

  "gcode_macro _DOOR_OPENED" = {
    gcode = ''
      # Store current light state before changing
      {% set current_red = printer["neopixel chamber_lights"].color_data[0][0] %}
      {% set current_green = printer["neopixel chamber_lights"].color_data[0][1] %}
      {% set current_blue = printer["neopixel chamber_lights"].color_data[0][2] %}
      {% set current_white = printer["neopixel chamber_lights"].color_data[0][3] if printer["neopixel chamber_lights"].color_data[0]|length > 3 else 0 %}
      
      # Save current state to restore later
      SET_GCODE_VARIABLE MACRO=_DOOR_CLOSED VARIABLE=saved_red VALUE={current_red}
      SET_GCODE_VARIABLE MACRO=_DOOR_CLOSED VARIABLE=saved_green VALUE={current_green}
      SET_GCODE_VARIABLE MACRO=_DOOR_CLOSED VARIABLE=saved_blue VALUE={current_blue}
      SET_GCODE_VARIABLE MACRO=_DOOR_CLOSED VARIABLE=saved_white VALUE={current_white}
      
      # Turn on bright white lights for visibility
      SET_LED LED=chamber_lights RED=1.0 GREEN=1.0 BLUE=1.0 WHITE=1.0
      
      M117 Door opened
    '';
  };

  "gcode_macro _DOOR_CLOSED" = {
    variable_saved_red = 0.0;
    variable_saved_green = 0.0;
    variable_saved_blue = 0.0;
    variable_saved_white = 0.0;
    gcode = ''
      # Restore previously saved light state
      {% set red = printer["gcode_macro _DOOR_CLOSED"].saved_red %}
      {% set green = printer["gcode_macro _DOOR_CLOSED"].saved_green %}
      {% set blue = printer["gcode_macro _DOOR_CLOSED"].saved_blue %}
      {% set white = printer["gcode_macro _DOOR_CLOSED"].saved_white %}
      
      SET_LED LED=chamber_lights RED={red} GREEN={green} BLUE={blue} WHITE={white}
      
      M117 Door closed
    '';
  };
}
