{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Pause / Resume / Cancel Macros
  #####################################################################

  "gcode_macro PAUSE" = {
    description = "Pause the running print";
    rename_existing = "PAUSE_BASE";
    gcode = ''
      {% set E = params.E|default(${config.retraction.pause_retract})|float %}
      {% set z_hop = ${toString config.movement.pause_z_hop} %}
      
      {% if printer.pause_resume.is_paused %}
        RESPOND MSG="Print is already paused"
      {% else %}
        SAVE_GCODE_STATE NAME=PAUSE_STATE
        SET_GCODE_VARIABLE MACRO=RESUME VARIABLE=etemp VALUE={printer['extruder'].target}
        
        FILAMENT_SENSOR_DISABLE
        PAUSE_BASE
        
        G91
        {% if printer.extruder.can_extrude %}
          G1 E-{E} F2100
        {% endif %}
        
        {% if (printer.gcode_move.position.z + z_hop) < printer.toolhead.axis_maximum.z %}
          G1 Z{z_hop} F900
        {% endif %}
        
        G90
        G0 X{printer.toolhead.axis_maximum.x // 2} Y${toString config.movement.pause_y_position} F${toString config.speeds.travel}
        
        M104 S0  ; turn off hotend
        SET_IDLE_TIMEOUT TIMEOUT=43200  ; 12 hours
        
        _SET_CHAMBER_PAUSED
        M117 Print paused
      {% endif %}
    '';
  };

  "gcode_macro RESUME" = {
    description = "Resume the paused print";
    rename_existing = "RESUME_BASE";
    variable_etemp = 0;
    gcode = ''
      {% set E = params.E|default(${config.retraction.pause_retract})|float %}
      
      {% if not printer.pause_resume.is_paused %}
        RESPOND MSG="Print is not paused"
      {% else %}
        # Heat back up if needed
        {% if etemp > 0 %}
          M109 S{etemp|int}
        {% endif %}
        
        FILAMENT_SENSOR_ENABLE
        SET_IDLE_TIMEOUT TIMEOUT={printer.configfile.settings.idle_timeout.timeout}
        
        RESTORE_GCODE_STATE NAME=PAUSE_STATE MOVE=1 MOVE_SPEED=100
        
        {% if printer.extruder.can_extrude %}
          G91
          G1 E{E} F2100
          G90
        {% endif %}
        
        _SET_CHAMBER_PRINTING
        M117 Printing...
        
        RESUME_BASE
      {% endif %}
    '';
  };

  "gcode_macro CANCEL_PRINT" = {
    description = "Cancel the running print";
    rename_existing = "CANCEL_PRINT_BASE";
    gcode = ''
      TURN_OFF_HEATERS
      CANCEL_PRINT_BASE
      
      G91
      G1 Z10 F3000
      G90
      G0 X{printer.toolhead.axis_maximum.x // 2} Y{printer.toolhead.axis_maximum.y - 5} F${toString config.speeds.travel}
      
      M107  ; turn off fan
      BED_MESH_CLEAR
      FILAMENT_SENSOR_ENABLE
      
      _SET_CHAMBER_IDLE
      _TOOLHEAD_LED_OFF
      
      M117 Print cancelled
    '';
  };
}
