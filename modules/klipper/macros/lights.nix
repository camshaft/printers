{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Toolhead LED Control (EBB36 Neopixel)
  #####################################################################

  "gcode_macro _TOOLHEAD_LED_ON" = {
    gcode = ''
      SET_LED LED=toolhead_rgb RED=1 GREEN=1 BLUE=1 WHITE=1
    '';
  };

  "gcode_macro _TOOLHEAD_LED_OFF" = {
    gcode = ''
      SET_LED LED=toolhead_rgb RED=0 GREEN=0 BLUE=0 WHITE=0
    '';
  };

  "gcode_macro STATUS_READY" = {
    description = "Set toolhead LED to ready (green)";
    gcode = ''
      SET_LED LED=toolhead_rgb RED=0 GREEN=1 BLUE=0 WHITE=0
    '';
  };

  "gcode_macro STATUS_BUSY" = {
    description = "Set toolhead LED to busy (orange)";
    gcode = ''
      SET_LED LED=toolhead_rgb RED=1 GREEN=0.5 BLUE=0 WHITE=0
    '';
  };

  "gcode_macro STATUS_HEATING" = {
    description = "Set toolhead LED to heating (red)";
    gcode = ''
      SET_LED LED=toolhead_rgb RED=1 GREEN=0 BLUE=0 WHITE=0
    '';
  };

  "gcode_macro STATUS_PRINTING" = {
    description = "Set toolhead LED to printing (white)";
    gcode = ''
      SET_LED LED=toolhead_rgb RED=1 GREEN=1 BLUE=1 WHITE=1
    '';
  };

  #####################################################################
  #   Chamber LED Control (Custom MCU)
  #####################################################################

  "gcode_macro CHAMBER_LIGHTS_ON" = {
    description = "Turn on chamber lights";
    gcode = ''
      SET_LED LED=chamber_lights RED=1.0 GREEN=1.0 BLUE=1.0
    '';
  };

  "gcode_macro CHAMBER_LIGHTS_OFF" = {
    description = "Turn off chamber lights";
    gcode = ''
      SET_LED LED=chamber_lights RED=0 GREEN=0 BLUE=0
    '';
  };

  "gcode_macro _SET_CHAMBER_IDLE" = {
    gcode = ''
      SET_LED LED=chamber_lights RED=${config.leds.chamber.idle_color.r} GREEN=${config.leds.chamber.idle_color.g} BLUE=${config.leds.chamber.idle_color.b}
    '';
  };

  "gcode_macro _SET_CHAMBER_PRINTING" = {
    gcode = ''
      SET_LED LED=chamber_lights RED=1.0 GREEN=1.0 BLUE=1.0
    '';
  };

  "gcode_macro _SET_CHAMBER_PAUSED" = {
    gcode = ''
      SET_LED LED=chamber_lights RED=1.0 GREEN=0.5 BLUE=0.0
    '';
  };

  "gcode_macro _SET_CHAMBER_ERROR" = {
    gcode = ''
      SET_LED LED=chamber_lights RED=1.0 GREEN=0.0 BLUE=0.0
    '';
  };

  #####################################################################
  #   Case Light (Leviathan LED-STRIP port)
  #####################################################################

  "gcode_macro CASELIGHT_ON" = {
    description = "Turn on case lights";
    gcode = ''
      SET_PIN PIN=caselight VALUE=1.0
    '';
  };

  "gcode_macro CASELIGHT_OFF" = {
    description = "Turn off case lights";
    gcode = ''
      SET_PIN PIN=caselight VALUE=0
    '';
  };

  "gcode_macro CASELIGHT_DIM" = {
    description = "Set case lights to dim";
    gcode = ''
      SET_PIN PIN=caselight VALUE=0.2
    '';
  };
}
