{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pins = config.pins;
  motor = config.motors.z;
in {
  #####################################################################
  #   Z Steppers - Quad Gantry (4 motors)
  #   
  #   Drivers: TMC2209 on Leviathan standard stepper ports
  #   
  #   Layout (looking from front):
  #     Z0 - Front Left
  #     Z1 - Rear Left
  #     Z2 - Rear Right
  #     Z3 - Front Right
  #####################################################################

  #####################################################################
  #   Z0 Stepper - Front Left
  #   Connected to Leviathan STEPPER 0
  #   
  #   Note: Using physical endstop switch for Z homing
  #   The Cartographer is used for probing/bed mesh but not for initial homing
  #####################################################################
  
  stepper_z = {
    step_pin = pins.leviathan.stepper.s0.step;
    dir_pin = "!${pins.leviathan.stepper.s0.dir}";
    enable_pin = pins.leviathan.stepper.s0.enable;
    endstop_pin = pins.leviathan.endstop.z;  # Physical Z endstop switch
    
    rotation_distance = motor.rotation_distance;
    gear_ratio = motor.gear_ratio;
    microsteps = motor.microsteps;
    
    position_min = -5;
    position_max = config.dimensions.max_z;
    position_endstop = 0;  # Required for physical endstop
    
    homing_speed = config.speeds.homing_z;
    second_homing_speed = config.speeds.second_homing_z;
    homing_retract_dist = 3;  # Physical endstop can retract
  };

  "tmc2209 stepper_z" = {
    uart_pin = pins.leviathan.stepper.s0.uart;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_z" = {
    motor = motor.model;
    tuning_goal = "silent";
  };

  #####################################################################
  #   Z1 Stepper - Rear Left
  #   Connected to Leviathan STEPPER 1
  #####################################################################
  
  stepper_z1 = {
    step_pin = pins.leviathan.stepper.s1.step;
    dir_pin = pins.leviathan.stepper.s1.dir;
    enable_pin = pins.leviathan.stepper.s1.enable;
    
    rotation_distance = motor.rotation_distance;
    gear_ratio = motor.gear_ratio;
    microsteps = motor.microsteps;
  };

  "tmc2209 stepper_z1" = {
    uart_pin = pins.leviathan.stepper.s1.uart;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_z1" = {
    motor = motor.model;
    tuning_goal = "silent";
  };

  #####################################################################
  #   Z2 Stepper - Rear Right
  #   Connected to Leviathan STEPPER 2
  #####################################################################
  
  stepper_z2 = {
    step_pin = pins.leviathan.stepper.s2.step;
    dir_pin = "!${pins.leviathan.stepper.s2.dir}";
    enable_pin = pins.leviathan.stepper.s2.enable;
    
    rotation_distance = motor.rotation_distance;
    gear_ratio = motor.gear_ratio;
    microsteps = motor.microsteps;
  };

  "tmc2209 stepper_z2" = {
    uart_pin = pins.leviathan.stepper.s2.uart;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_z2" = {
    motor = motor.model;
    tuning_goal = "silent";
  };

  #####################################################################
  #   Z3 Stepper - Front Right
  #   Connected to Leviathan STEPPER 3
  #####################################################################
  
  stepper_z3 = {
    step_pin = pins.leviathan.stepper.s3.step;
    dir_pin = pins.leviathan.stepper.s3.dir;
    enable_pin = pins.leviathan.stepper.s3.enable;
    
    rotation_distance = motor.rotation_distance;
    gear_ratio = motor.gear_ratio;
    microsteps = motor.microsteps;
  };

  "tmc2209 stepper_z3" = {
    uart_pin = pins.leviathan.stepper.s3.uart;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_z3" = {
    motor = motor.model;
    tuning_goal = "silent";
  };
}
