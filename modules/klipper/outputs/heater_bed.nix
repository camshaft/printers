{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pins = config.pins;
in {
  #####################################################################
  #   Bed Heater
  #   
  #   Connected to Leviathan HE_BED (PG11)
  #   SSR controlled AC heater (typically 750W for 350mm)
  #####################################################################

  heater_bed = {
    heater_pin = pins.leviathan.heater.bed;
    sensor_type = "ATC Semitec 104NT-4-R025H42G";
    sensor_pin = pins.leviathan.thermistor.th1;
    pullup_resistor = 2200;
    
    # Adjust max_power for your bed
    # Rule of thumb: 0.4W/cm²
    # 350mm bed: 350*350 = 122500mm² = 1225cm²
    # At 750W = 0.61W/cm², so use 0.6 max_power
    max_power = config.heaters.bed.max_power;
    min_temp = 0;
    max_temp = config.heaters.bed.max_temp;
    
    # PID tuning - run PID_CALIBRATE HEATER=heater_bed TARGET=100
    control = "pid";
    pid_kp = "58.437";
    pid_ki = "2.347";
    pid_kd = "363.769";
  };
}
