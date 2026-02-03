{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Debug & Utility Macros
  #####################################################################

  "gcode_macro DUMP_PARAMETERS" = {
    description = "Debug: dump all Klipper parameters";
    gcode = ''
      {% set parameters = namespace(output = "") %}
      {% for name in printer %}
        {% set parameters.output = parameters.output + "printer['%s'] = %s\n" % (name, printer[name]) %}
      {% endfor %}
      { action_respond_info(parameters.output) }
    '';
  };

  "gcode_macro GET_PROBE_LIMITS" = {
    description = "Get probe limits for bed mesh";
    gcode = ''
      {% set probe = printer.configfile.settings.cartographer %}
      {% set x_min = printer.toolhead.axis_minimum.x %}
      {% set x_max = printer.toolhead.axis_maximum.x %}
      {% set y_min = printer.toolhead.axis_minimum.y %}
      {% set y_max = printer.toolhead.axis_maximum.y %}
      
      { action_respond_info("Probe X offset: %s" % probe.x_offset) }
      { action_respond_info("Probe Y offset: %s" % probe.y_offset) }
      { action_respond_info("X min: %s, X max: %s" % (x_min + probe.x_offset, x_max - probe.x_offset)) }
      { action_respond_info("Y min: %s, Y max: %s" % (y_min + probe.y_offset, y_max - probe.y_offset)) }
    '';
  };

  "gcode_macro DUMP_CONFIG" = {
    description = "Dump current printer configuration";
    gcode = ''
      {% for key, value in printer.configfile.settings.items() %}
        { action_respond_info("[%s]" % key) }
        {% for setting, val in value.items() %}
          { action_respond_info("  %s = %s" % (setting, val)) }
        {% endfor %}
      {% endfor %}
    '';
  };

  "gcode_macro TEST_SPEED" = {
    description = "Test movement at various speeds";
    gcode = ''
      {% set SPEED = params.SPEED|default(300)|int %}
      {% set ITERATIONS = params.ITERATIONS|default(5)|int %}
      
      _ENSURE_HOMED
      
      G90
      G0 Z20 F3000
      
      {% for i in range(ITERATIONS) %}
        G0 X10 Y10 F{SPEED * 60}
        G0 X340 Y340 F{SPEED * 60}
        G0 X10 Y340 F{SPEED * 60}
        G0 X340 Y10 F{SPEED * 60}
      {% endfor %}
      
      G0 X175 Y175 F{SPEED * 60}
      { action_respond_info("Speed test complete at %s mm/s" % SPEED) }
    '';
  };
}
