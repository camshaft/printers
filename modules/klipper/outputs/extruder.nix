{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pins = config.pins;
  motor = config.motors.extruder;
in {
  #####################################################################
  #   Extruder - WWG2 (WristWatch G2) on EBB36 Gen2
  #   
  #   Motor: LDO-36STH20-1004AHG (or similar pancake stepper)
  #   Driver: TMC2209 on EBB36
  #   Gear Ratio: 57.14:1 (Galileo 2 internals)
  #####################################################################

  extruder = {
    step_pin = pins.ebb36.extruder.step;
    dir_pin = pins.ebb36.extruder.dir;
    enable_pin = pins.ebb36.extruder.enable;

    rotation_distance = motor.rotation_distance;
    gear_ratio = motor.gear_ratio;
    microsteps = motor.microsteps;
    full_steps_per_rotation = motor.full_steps_per_rotation;
    
    nozzle_diameter = "0.400";
    filament_diameter = config.filament.diameter;
    
    # Heater on EBB36
    heater_pin = pins.ebb36.heater;
    sensor_type = "ATC Semitec 104NT-4-R025H42G";
    sensor_pin = pins.ebb36.thermistor;
    pullup_resistor = 2200;
    
    min_temp = 0;
    max_temp = config.heaters.extruder.max_temp;
    max_power = config.heaters.extruder.max_power;
    min_extrude_temp = config.heaters.extruder.min_extrude_temp;
    max_extrude_only_distance = 150;
    max_extrude_cross_section = 5;
    
    # PID tuning - run PID_CALIBRATE HEATER=extruder TARGET=245
    control = "pid";
    pid_kp = "26.213";
    pid_ki = "1.304";
    pid_kd = "131.721";
    
    # Pressure advance - tune with PA_CAL or tower test
    pressure_advance = "0.04";
    pressure_advance_smooth_time = "0.040";
  };

  "tmc2209 extruder" = {
    uart_pin = pins.ebb36.extruder.uart;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc extruder" = {
    motor = motor.model;
  };
}
