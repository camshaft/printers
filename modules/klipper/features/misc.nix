{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Core Features
  #####################################################################

  virtual_sdcard = {
    path = "/gcodes";
    on_error_gcode = "CANCEL_PRINT";
  };

  pause_resume = { };
  display_status = { };
  exclude_object = { };
  respond = { };

  #####################################################################
  #   Skew Correction
  #####################################################################

  skew_correction = { };

  #####################################################################
  #   Firmware Retraction
  #####################################################################

  firmware_retraction = {
    retract_length = config.retraction.length;
    retract_speed = config.retraction.speed;
    unretract_extra_length = 0;
    unretract_speed = config.retraction.unretract_speed;
  };

  #####################################################################
  #   Arc Support
  #####################################################################

  gcode_arcs = {
    resolution = "0.1";
  };

  #####################################################################
  #   Force Move (for initial setup/debugging)
  #####################################################################

  force_move = {
    enable_force_move = true;
  };

  #####################################################################
  #   Idle Timeout
  #####################################################################

  idle_timeout = {
    timeout = 1800;  # 30 minutes
    gcode = ''
      TURN_OFF_HEATERS
      M84  ; disable steppers
      _SET_CHAMBER_IDLE
    '';
  };
}
