{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Print Start Macro
  #   
  #   Usage from slicer (PrusaSlicer/SuperSlicer):
  #     PRINT_START EXTRUDER=[first_layer_temperature] BED=[first_layer_bed_temperature] CHAMBER=[chamber_temperature]
  #####################################################################

  "gcode_macro PRINT_START" = {
    description = "Start print sequence";
    gcode = ''
      {% set BED_TEMP = params.BED|default(60)|float %}
      {% set EXTRUDER_TEMP = params.EXTRUDER|default(200)|float %}
      {% set CHAMBER_TEMP = params.CHAMBER|default(0)|float %}
      {% set MATERIAL = params.MATERIAL|default("PLA")|string %}
      
      {% set config = printer["gcode_macro _Configuration"] %}
      {% set probe_temp = config.probe_temp|int %}
      
      # Turn on lights
      CHAMBER_LIGHTS_ON
      _TOOLHEAD_LED_ON
      
      # Start heating bed
      M140 S{BED_TEMP}
      M117 Heating bed...
      
      #######################
      #  Home all axes     #
      #######################
      M117 Homing...
      G28
      
      # Move to center and wait for bed temp
      G0 X${toString config.dimensions.home_x} Y${toString config.dimensions.home_y} Z${toString config.movement.travel_clearance} F${toString config.speeds.travel}
      M190 S{BED_TEMP}
      M117 Bed at temp
      
      #######################
      #  Heat chamber      #
      #######################
      {% if CHAMBER_TEMP > 0 %}
        M117 Heating chamber to {CHAMBER_TEMP}C...
        NEVERMORE_ON
        TEMPERATURE_WAIT SENSOR="temperature_sensor chamber" MINIMUM={CHAMBER_TEMP}
        M117 Chamber at temp
      {% endif %}
      
      ############################
      # Heat nozzle to probe temp #
      ############################
      M117 Heating nozzle for probing...
      M104 S{probe_temp}
      TEMPERATURE_WAIT SENSOR=extruder MINIMUM={probe_temp - 5} MAXIMUM={probe_temp + 5}
      
      ############################
      # Quad gantry level        #
      ############################
      M117 Leveling gantry...
      QUAD_GANTRY_LEVEL
      
      ############################
      # Bed mesh                  #
      ############################
      M117 Creating bed mesh...
      BED_MESH_CALIBRATE ADAPTIVE=1
      
      # Move to front for heating
      G0 X${toString config.dimensions.home_x} Y10 Z${toString config.movement.travel_clearance} F${toString config.speeds.travel}
      
      ############################
      # Heat extruder to print   #
      ############################
      M117 Heating extruder to {EXTRUDER_TEMP}C...
      M109 S{EXTRUDER_TEMP}
      M117 Extruder at temp
      
      ############################
      # Prime line               #
      ############################
      M117 Priming...
      PRIME_LINE
      
      # Set chamber lights for printing
      _SET_CHAMBER_PRINTING
      STATUS_READY
      
      M117 Printing...
    '';
  };
}
