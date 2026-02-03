{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Filament Operations
  #####################################################################

  "gcode_macro LOAD_FILAMENT" = {
    description = "Load filament into toolhead";
    gcode = ''
      {% set TEMP = params.TEMP|default(${toString config.filament.load_temp})|int %}
      {% set MIN_TEMP = (TEMP * 0.98)|int %}
      {% set LOAD_DISTANCE = ${toString config.filament.load_distance} %}
      
      SAVE_GCODE_STATE NAME=LOAD_FILAMENT_STATE
      
      # Heat if needed
      {% if printer.extruder.target < TEMP %}
        M104 S{TEMP}
      {% endif %}
      
      M117 Heating for filament load...
      TEMPERATURE_WAIT SENSOR="extruder" MINIMUM={MIN_TEMP}
      
      _TOOLHEAD_LED_ON
      M117 Loading filament...
      
      M83                         ; relative extrusion
      G1 E{LOAD_DISTANCE * 0.7} F${toString config.filament.load_speed}  ; load quickly
      G1 E{LOAD_DISTANCE * 0.2} F300  ; load slowly through meltzone
      G1 E{LOAD_DISTANCE * 0.1} F150  ; prime
      G1 E-2 F1800               ; slight retract
      
      M400
      M117 Load Complete!
      M300 S660 P200  ; beep
      
      _TOOLHEAD_LED_OFF
      
      RESTORE_GCODE_STATE NAME=LOAD_FILAMENT_STATE
    '';
  };

  "gcode_macro UNLOAD_FILAMENT" = {
    description = "Unload filament from toolhead";
    gcode = ''
      {% set TEMP = params.TEMP|default(${toString config.filament.load_temp})|int %}
      {% set MIN_TEMP = (TEMP * 0.98)|int %}
      {% set UNLOAD_DISTANCE = ${toString config.filament.unload_distance} %}
      
      SAVE_GCODE_STATE NAME=UNLOAD_FILAMENT_STATE
      
      # Heat if needed
      {% if printer.extruder.target < TEMP %}
        M104 S{TEMP}
      {% endif %}
      
      M117 Heating for filament unload...
      TEMPERATURE_WAIT SENSOR="extruder" MINIMUM={MIN_TEMP}
      
      _TOOLHEAD_LED_ON
      M117 Unloading filament...
      
      M83                         ; relative extrusion
      G1 E10 F300                 ; extrude a bit to soften tip
      G1 E-10 F3600               ; quick retract to form tip
      G4 P200                     ; pause
      G1 E-{UNLOAD_DISTANCE * 0.6} F${toString config.filament.unload_speed}  ; fast retract
      G1 E-{UNLOAD_DISTANCE * 0.4} F300  ; slow finish
      
      M400
      M117 Unload Complete!
      M300 S440 P200  ; beep
      
      _TOOLHEAD_LED_OFF
      
      RESTORE_GCODE_STATE NAME=UNLOAD_FILAMENT_STATE
    '';
  };

  #####################################################################
  #   Filament Sensor Control
  #####################################################################

  "gcode_macro FILAMENT_SENSOR_ENABLE" = {
    description = "Enable filament sensors";
    gcode = ''
      SET_FILAMENT_SENSOR SENSOR=switch_sensor ENABLE=1
      SET_FILAMENT_SENSOR SENSOR=encoder_sensor ENABLE=1
    '';
  };

  "gcode_macro FILAMENT_SENSOR_DISABLE" = {
    description = "Disable filament sensors";
    gcode = ''
      SET_FILAMENT_SENSOR SENSOR=switch_sensor ENABLE=0
      SET_FILAMENT_SENSOR SENSOR=encoder_sensor ENABLE=0
    '';
  };
}
