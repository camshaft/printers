{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pins = config.pins;
in {
  #####################################################################
  #   Fans
  #####################################################################

  #####################################################################
  #   Part Cooling Fan - EBB36 FAN0
  #   A4T uses dual 4010 blowers
  #####################################################################
  
  fan = {
    pin = pins.ebb36.fan.part;
    kick_start_time = "0.5";
    off_below = "0.10";
  };

  #####################################################################
  #   Hotend Fan - EBB36 FAN1
  #   A4T uses 2510 axial fan for hotend cooling
  #   
  #   Note: PA0 set at startup in firmware to keep this on at boot
  #####################################################################
  
  "heater_fan hotend_fan" = {
    pin = pins.ebb36.fan.hotend;
    max_power = "1.0";
    kick_start_time = "0.5";
    heater = "extruder";
    heater_temp = "50.0";
  };

  #####################################################################
  #   Electronics Bay Cooling - 4x Noctua NF-A6x25 FLX
  #   
  #   Split across multiple fan ports for better control
  #   Using Leviathan FAN2, FAN4, FAN5 and Extension FAN1
  #####################################################################
  
  "controller_fan electronics_fan_1" = {
    pin = pins.leviathan.fan.f2;
    kick_start_time = "0.5";
    heater = "heater_bed";
    fan_speed = "0.5";
    idle_timeout = 30;
    idle_speed = "0.3";
  };

  "controller_fan electronics_fan_2" = {
    pin = pins.leviathan.fan.f4;
    kick_start_time = "0.5";
    heater = "heater_bed";
    fan_speed = "0.5";
    idle_timeout = 30;
    idle_speed = "0.3";
  };

  "controller_fan electronics_fan_3" = {
    pin = pins.leviathan.fan.f5;
    kick_start_time = "0.5";
    heater = "heater_bed";
    fan_speed = "0.5";
    idle_timeout = 30;
    idle_speed = "0.3";
  };

  "controller_fan electronics_fan_4" = {
    pin = pins.leviathan_ext.fan.f1;
    kick_start_time = "0.5";
    heater = "heater_bed";
    fan_speed = "0.5";
    idle_timeout = 30;
    idle_speed = "0.3";
  };

  #####################################################################
  #   Exhaust Fan - Leviathan FAN3
  #   Chamber exhaust / Nevermore slot
  #####################################################################
  
  "heater_fan exhaust_fan" = {
    pin = pins.leviathan.fan.f3;
    max_power = "1.0";
    shutdown_speed = "0.0";
    kick_start_time = "5.0";
    heater = "heater_bed";
    heater_temp = "60";
    fan_speed = "1.0";
  };

  #####################################################################
  #   Nevermore / Bed Fans - Leviathan Extension FAN0
  #   Carbon filter recirculation
  #####################################################################
  
  "fan_generic nevermore" = {
    pin = pins.leviathan_ext.fan.f0;
    max_power = "1.0";
    kick_start_time = "0.5";
  };

  #####################################################################
  #   LEDs
  #####################################################################

  #####################################################################
  #   Toolhead LEDs - A4T Neopixels on EBB36
  #####################################################################
  
  "neopixel toolhead_rgb" = {
    pin = pins.ebb36.led.neopixel;
    chain_count = config.leds.toolhead.count;
    color_order = config.leds.toolhead.color_order;
    initial_RED = "0.0";
    initial_GREEN = "0.0";
    initial_BLUE = "0.0";
    initial_WHITE = "0.0";
  };

  #####################################################################
  #   Case Light - Leviathan LED-STRIP port (PWM)
  #####################################################################
  
  "output_pin caselight" = {
    pin = pins.leviathan.led_strip;
    pwm = true;
    hardware_pwm = false;
    value = "0.2";
    shutdown_value = 0;
    cycle_time = "0.00025";
  };

  #####################################################################
  #   Buzzer - Leviathan Extension
  #####################################################################
  
  "pwm_cycle_time _beeper" = {
    pin = pins.leviathan_ext.buzzer;
    shutdown_value = 0;
    value = 0;
  };
}
