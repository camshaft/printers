{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Print End Macro
  #####################################################################

  "gcode_macro PRINT_END" = {
    description = "End print sequence";
    gcode = ''
      # Safe anti-stringing move coords
      {% set th = printer.toolhead %}
      {% set x_safe = th.position.x + 20 * (1 if th.axis_maximum.x - th.position.x > 20 else -1) %}
      {% set y_safe = th.position.y + 20 * (1 if th.axis_maximum.y - th.position.y > 20 else -1) %}
      {% set z_safe = [th.position.z + 2, th.axis_maximum.z]|min %}
      
      SAVE_GCODE_STATE NAME=STATE_PRINT_END
      
      M400                           ; wait for buffer to clear
      G92 E0                         ; zero the extruder
      G1 E-5.0 F1800                 ; retract filament
      
      TURN_OFF_HEATERS
      
      G90                            ; absolute positioning
      G0 X{x_safe} Y{y_safe} Z{z_safe} F${toString config.speeds.travel}  ; move nozzle to remove stringing
      G0 X{th.axis_maximum.x//2} Y{th.axis_maximum.y - 2} F${toString config.speeds.travel}  ; park nozzle at rear
      M107                           ; turn off fan
      
      BED_MESH_CLEAR
      
      # Run Nevermore for a bit to filter chamber air
      NEVERMORE_ON
      UPDATE_DELAYED_GCODE ID=_NEVERMORE_OFF_DELAYED DURATION=300
      
      # Set chamber lights for idle
      _SET_CHAMBER_IDLE
      _TOOLHEAD_LED_OFF
      
      M117 Print complete!
      M300 S440 P200  ; beep to notify
      M300 S660 P200
      
      RESTORE_GCODE_STATE NAME=STATE_PRINT_END
    '';
  };

  "delayed_gcode _NEVERMORE_OFF_DELAYED" = {
    initial_duration = 0;
    gcode = ''
      NEVERMORE_OFF
    '';
  };
}
