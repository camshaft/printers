{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pins = config.pins;
in {
  #####################################################################
  #   Filament Sensor - BTT SFS V2.0
  #   
  #   SFS V2.0 has both a switch sensor and motion encoder
  #   Detection length: 2.88mm (motion sensor accuracy)
  #   
  #   Connect switch to Leviathan FIL_DET (PC0)
  #   Connect motion encoder to a second input (PG12)
  #####################################################################

  #####################################################################
  #   Filament Switch Sensor (runout detection)
  #####################################################################
  
  "filament_switch_sensor switch_sensor" = {
    switch_pin = pins.leviathan.filament.detect;
    pause_on_runout = false;
    runout_gcode = ''
      PAUSE
      M117 Filament switch runout
    '';
    insert_gcode = ''
      M117 Filament inserted
    '';
  };

  #####################################################################
  #   Filament Motion Sensor (jam/clog detection)
  #####################################################################
  
  "filament_motion_sensor encoder_sensor" = {
    switch_pin = pins.leviathan.filament.motion;
    detection_length = config.filament.sfs_detection_length;
    extruder = "extruder";
    pause_on_runout = false;
    runout_gcode = ''
      PAUSE
      M117 Filament encoder runout
    '';
    insert_gcode = ''
      M117 Filament encoder inserted
    '';
  };
}
