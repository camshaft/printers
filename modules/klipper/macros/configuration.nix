{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Configuration Macro
  #   
  #   This macro stores configuration values that can be referenced
  #   by other macros using: printer["gcode_macro _Configuration"].value
  #####################################################################

  "gcode_macro _Configuration" = {
    description = "Configuration values for macros";
    
    # Printer dimensions
    variable_bed_size = config.dimensions.bed_size;
    variable_home_x = config.dimensions.home_x;
    variable_home_y = config.dimensions.home_y;
    variable_max_z = config.dimensions.max_z;
    
    # Speeds
    variable_travel_speed = config.speeds.travel;
    variable_travel_clearance = config.movement.travel_clearance;
    
    # Probe settings
    variable_probe_temp = config.probe.probe_temp;
    variable_cartographer_touch = config.probe.use_touch;
    
    # Pause settings
    variable_pause_padding = config.movement.pause_y_position;
    variable_pause_z_hop = config.movement.pause_z_hop;
    
    # Purge settings
    variable_purge_retract = config.retraction.pause_retract;
    
    gcode = "";  # No actual gcode - this is just for variable storage
  };
}
