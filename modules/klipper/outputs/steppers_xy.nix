{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pins = config.pins;
  motor = config.motors.xy;
in {
  #####################################################################
  #   A/B Steppers - AWD Configuration (4 motors)
  #   
  #   Motors: 8x LDO 42STH48-2504AH (0.9°, 2.5A rated)
  #   Drivers: TMC5160 on Leviathan HV ports (48V capable)
  #   
  #   AWD Layout:
  #     - stepper_x (B motor) - Rear Left
  #     - stepper_y (A motor) - Rear Right  
  #     - stepper_x1 (B1 motor) - Front Right
  #     - stepper_y1 (A1 motor) - Front Left
  #   
  #   The front motors are installed upside down relative to rear,
  #   so dir pins within same set should be opposite sign.
  #####################################################################

  #####################################################################
  #   B Stepper - Rear Left (Primary X)
  #   Connected to Leviathan HV STEPPER 0
  #####################################################################
  
  stepper_x = {
    step_pin = pins.leviathan.hv_stepper.s0.step;
    dir_pin = "!${pins.leviathan.hv_stepper.s0.dir}";
    enable_pin = pins.leviathan.hv_stepper.s0.enable;
    endstop_pin = pins.leviathan.endstop.x;
    
    rotation_distance = motor.rotation_distance;
    microsteps = motor.microsteps;
    full_steps_per_rotation = motor.full_steps_per_rotation;
    
    position_min = 0;
    position_endstop = config.dimensions.bed_size;
    position_max = config.dimensions.bed_size;
    
    homing_speed = config.speeds.homing;
    homing_retract_dist = 5;
    homing_positive_dir = true;
  };

  "tmc5160 stepper_x" = {
    cs_pin = pins.leviathan.hv_stepper.s0.cs;
    spi_bus = pins.leviathan.spi4.bus;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_x" = {
    motor = motor.model;
  };

  #####################################################################
  #   A Stepper - Rear Right (Primary Y)
  #   Connected to Leviathan HV STEPPER 1
  #####################################################################
  
  stepper_y = {
    step_pin = pins.leviathan.hv_stepper.s1.step;
    dir_pin = "!${pins.leviathan.hv_stepper.s1.dir}";
    enable_pin = pins.leviathan.hv_stepper.s1.enable;
    endstop_pin = pins.leviathan.endstop.y;
    
    rotation_distance = motor.rotation_distance;
    microsteps = motor.microsteps;
    full_steps_per_rotation = motor.full_steps_per_rotation;
    
    position_min = 0;
    position_endstop = config.dimensions.bed_size;
    position_max = config.dimensions.bed_size;
    
    homing_speed = config.speeds.homing;
    homing_retract_dist = 5;
    homing_positive_dir = true;
  };

  "tmc5160 stepper_y" = {
    cs_pin = pins.leviathan.hv_stepper.s1.cs;
    spi_bus = pins.leviathan.spi4.bus;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_y" = {
    motor = motor.model;
  };

  #####################################################################
  #   B1 Stepper - Front Right (AWD X)
  #   Connected to Leviathan Extension HV STEPPER 2
  #####################################################################
  
  stepper_x1 = {
    step_pin = pins.leviathan_ext.hv_stepper.s2.step;
    dir_pin = pins.leviathan_ext.hv_stepper.s2.dir;  # Opposite direction (no inversion - front motor upside down)
    enable_pin = pins.leviathan_ext.hv_stepper.s2.enable;
    
    rotation_distance = motor.rotation_distance;
    microsteps = motor.microsteps;
    full_steps_per_rotation = motor.full_steps_per_rotation;
  };

  "tmc5160 stepper_x1" = {
    cs_pin = pins.leviathan_ext.hv_stepper.s2.cs;
    spi_bus = pins.leviathan_ext.spi2.bus;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_x1" = {
    motor = motor.model;
  };

  #####################################################################
  #   A1 Stepper - Front Left (AWD Y)
  #   Connected to Leviathan Extension HV STEPPER 3
  #####################################################################
  
  stepper_y1 = {
    step_pin = pins.leviathan_ext.hv_stepper.s3.step;
    dir_pin = pins.leviathan_ext.hv_stepper.s3.dir;  # Opposite direction (no inversion - front motor upside down)
    enable_pin = pins.leviathan_ext.hv_stepper.s3.enable;
    
    rotation_distance = motor.rotation_distance;
    microsteps = motor.microsteps;
    full_steps_per_rotation = motor.full_steps_per_rotation;
  };

  "tmc5160 stepper_y1" = {
    cs_pin = pins.leviathan_ext.hv_stepper.s3.cs;
    spi_bus = pins.leviathan_ext.spi2.bus;
    interpolate = false;
    run_current = motor.run_current;
    sense_resistor = motor.sense_resistor;
    stealthchop_threshold = 0;
  };

  "autotune_tmc stepper_y1" = {
    motor = motor.model;
  };
}
