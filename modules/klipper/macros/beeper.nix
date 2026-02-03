{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Buzzer / Beeper (Leviathan Extension)
  #####################################################################

  "gcode_macro M300" = {
    description = "Play a tone - Usage: M300 S<frequency> P<duration_ms>";
    gcode = ''
      {% set S = params.S|default(1000)|int %}
      {% set P = params.P|default(100)|int %}
      {% set L = 0.5 %}
      {% if S <= 0 %}
        {% set F = 1 %}
        {% set L = 0 %}
      {% elif S >= 10000 %}
        {% set F = 0 %}
      {% else %}
        {% set F = 1/S %}
      {% endif %}
      SET_PIN PIN=_beeper VALUE={L} CYCLE_TIME={F}
      G4 P{P}
      SET_PIN PIN=_beeper VALUE=0
    '';
  };

  "gcode_macro BEEP" = {
    description = "Play a single beep";
    gcode = ''
      M300 S1000 P100
    '';
  };

  "gcode_macro BEEP_SUCCESS" = {
    description = "Play success tone";
    gcode = ''
      M300 S440 P100
      M300 S660 P100
      M300 S880 P200
    '';
  };

  "gcode_macro BEEP_ERROR" = {
    description = "Play error tone";
    gcode = ''
      M300 S880 P100
      M300 S440 P100
      M300 S220 P300
    '';
  };
}
