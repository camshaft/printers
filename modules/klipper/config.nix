{
  lib ? import <nixpkgs/lib>,
  ...
}:
#####################################################################
#   Common Configuration Values
#
#   This file contains all shared configuration values that can be
#   referenced throughout the klipper configuration. This includes
#   MCU identifiers, motor specifications, bed dimensions, etc.
#
#   All values are Nix expressions - any typo or undefined reference
#   will cause a build-time error rather than a runtime Klipper error.
#####################################################################
let
  # Import MCU modules to get their pin definitions
  leviathan_mcu = import ./mcus/leviathan.nix { inherit lib; };
  leviathan_ext_mcu = import ./mcus/leviathan_ext.nix { inherit lib; };
  ebb36_mcu = import ./mcus/ebb36.nix { inherit lib; };
  hbb_mcu = import ./mcus/hbb.nix { inherit lib; };
  chamber_mcu = import ./mcus/chamber.nix { inherit lib; };
  cartographer_mcu = import ./mcus/cartographer.nix { inherit lib; };
  host_mcu = import ./mcus/host.nix { inherit lib; };

  # Aggregate pins from all MCUs
  pins = {
    leviathan = leviathan_mcu._meta.pins;
    leviathan_ext = leviathan_ext_mcu._meta.pins;
    ebb36 = ebb36_mcu._meta.pins;
    hbb = hbb_mcu._meta.pins;
    chamber = chamber_mcu._meta.pins;
    cartographer = cartographer_mcu._meta.pins;
    host = host_mcu._meta.pins;

    # Raw pins (without MCU prefix) for board_pins aliases
    raw = {
      ebb36 = ebb36_mcu._meta.rawPins;
      hbb = hbb_mcu._meta.rawPins;
      chamber = chamber_mcu._meta.rawPins;
      cartographer = cartographer_mcu._meta.rawPins;
    };

    # Virtual pins
    virtual = {
      z_endstop = "probe:z_virtual_endstop";
    };
  };

  # Printer dimensions
  dimensions = {
    bed_size = 350; # mm - Voron 2.4 350mm
    max_z = 330; # mm - Maximum Z height
    home_x = 175; # mm - Center X for homing
    home_y = 175; # mm - Center Y for homing
  };

  #####################################################################
  #   Motor Specifications
  #
  #   All motors: LDO 42STH48-2504AH
  #   - 1.8° step angle (200 steps/rev)
  #   - 2.0A rated current
  #####################################################################
  motors = {
    # X/Y AWD Motors - LDO 42STH48-2504AH on TMC5160
    xy = {
      model = "ldo-42sth48-2504ah";
      full_steps_per_rotation = 200; # 1.8° stepper
      rotation_distance = 40; # GT2 20T pulley
      microsteps = 32;
      # Run current: ~70% of rated 2.0A for TMC5160
      run_current = "1.4";
      hold_current = "0.7";
      sense_resistor = "0.075"; # TMC5160 sense resistor
    };

    # Z Motors - LDO 42STH48-2504AH on TMC2209
    z = {
      model = "ldo-42sth48-2504ah";
      full_steps_per_rotation = 200; # 1.8° stepper
      rotation_distance = 40;
      gear_ratio = "80:16";
      microsteps = 32;
      run_current = "0.8";
      hold_current = "0.4";
      sense_resistor = "0.110"; # TMC2209 sense resistor
    };

    # Extruder Motor - WWG2 pancake stepper
    extruder = {
      model = "ldo-36sth20-1004ahg";
      full_steps_per_rotation = 200;
      # WWG2/Galileo 2 gear ratio
      rotation_distance = "22.6789511";
      gear_ratio = "57.14:1";
      microsteps = 32;
      run_current = "0.65";
      sense_resistor = "0.110";
    };
  };

  #####################################################################
  #   MCU Configuration
  #
  #   All boards use Katapult bootloader for easy updates.
  #   Leviathan acts as USB-to-CAN bridge.
  #   Chamber MCU (Pi Pico 2) uses USB serial.
  #####################################################################
  mcus = {
    # LDO Leviathan V1.3 - Main Controller
    # Acts as USB-to-CAN bridge
    leviathan = {
      # CAN bus UUID - find with: klipper-canbus-query can0
      canbus_uuid = "66c2b3792736";
      canbus_interface = "can0";
    };

    # BTT EBB36 Gen2 - Toolhead Controller (CANBUS)
    ebb36 = {
      # CAN bus UUID - find with: klipper-canbus-query can0
      canbus_uuid = "000000000000";
    };

    # Cartographer V3 Probe (CANBUS)
    #
    # Follow Cartographer documentation for firmware updates
    # Uses CAN bus for communication
    cartographer = {
      # CAN bus UUID - find with: klipper-canbus-query can0
      canbus_uuid = "000000000001";
    };

    # BTT HBB - Hot-key Button Board (USB)
    hbb = {
      # USB serial path - find with: ls -l /dev/serial/by-id/
      serial = "/dev/serial/by-id/usb-Klipper_rp2040_45474E621B0C442A-if00";
    };

    # Chamber MCU - Raspberry Pi Pico 2 (RP2350) via USB
    # Handles: LED strip, door sensor
    chamber = {
      # USB serial path - find with: ls -l /dev/serial/by-id/
      serial = "usb-Klipper_rp2350_chamber-if00";
    };
  };

  #####################################################################
  #   Movement & Speed Settings
  #####################################################################
  speeds = {
    travel = 18000; # mm/min - Non-printing moves
    travel_z = 30; # mm/s - Z travel speed
    homing = 25; # mm/s - Homing speed
    homing_z = 8; # mm/s - Z homing speed
    second_homing_z = 3; # mm/s - Second Z homing speed
    qgl = 300; # mm/s - QGL speed
    bed_mesh = 300; # mm/s - Bed mesh probing speed
  };

  #####################################################################
  #   Printer Velocity & Acceleration
  #####################################################################
  kinematics = {
    type = "corexy";
    max_velocity = 500; # mm/s - Maximum print velocity
    max_accel = 10000; # mm/s² - Maximum acceleration
    max_z_velocity = 30; # mm/s - Z axis max velocity
    max_z_accel = 350; # mm/s² - Z axis max acceleration
    square_corner_velocity = 5.0; # mm/s
  };

  #####################################################################
  #   Movement Helpers
  #####################################################################
  movement = {
    travel_clearance = 10; # mm - Height above bed for travel moves
    pause_z_hop = 10; # mm - Z hop when pausing
    pause_y_position = 5; # mm - Y position when paused (near front)
  };

  #####################################################################
  #   Retraction Settings
  #####################################################################
  retraction = {
    length = "0.5"; # mm - Firmware retraction length
    speed = 35; # mm/s - Retraction speed
    unretract_speed = 35; # mm/s - Unretract speed
    z_hop = "0.2"; # mm - Z hop during retraction
    pause_retract = "2.0"; # mm - Extra retract when pausing
  };

  #####################################################################
  #   Purge & Prime Settings
  #####################################################################
  purge = {
    prime_length = 20; # mm - Filament to extrude for prime line
    prime_speed = 1000; # mm/min - Prime line speed
  };

  #####################################################################
  #   Probe Settings (Cartographer V3)
  #####################################################################
  probe = {
    # Offset from nozzle to Cartographer center
    # Adjust based on your A4T/Xol carriage mounting
    x_offset = "0.0";
    y_offset = "21.0";
    # Touch vs scan preference
    use_touch = true;
    # Temperature to heat nozzle for probing (touch mode)
    probe_temp = 150;
  };

  #####################################################################
  #   Bed Mesh Settings
  #####################################################################
  bed_mesh = {
    mesh_min = "30, 30";
    mesh_max = "320, 320";
    probe_count = "20, 20";
    zero_reference = "175, 175";
    adaptive_margin = 10;
  };

  #####################################################################
  #   Quad Gantry Level Points (350mm)
  #####################################################################
  qgl = {
    gantry_corners = ''
      -60,-10
      410,420
    '';
    points = ''
      50,25
      50,275
      300,275
      300,25
    '';
  };

  #####################################################################
  #   Heater Settings
  #####################################################################
  heaters = {
    bed = {
      max_power = "0.6"; # 750W bed on 350mm = ~0.5W/cm²
      max_temp = 120;
    };
    extruder = {
      max_power = "1.0";
      max_temp = 300;
      min_extrude_temp = 170;
    };
  };

  #####################################################################
  #   Filament Settings
  #####################################################################
  filament = {
    diameter = "1.75";
    # BTT SFS V2.0 detection length
    sfs_detection_length = "2.88";
    # Load/unload settings
    load_temp = 230; # Temperature for loading
    load_distance = 75; # mm to extrude when loading
    load_speed = 600; # mm/min load speed
    unload_distance = 80; # mm to retract when unloading
    unload_speed = 600; # mm/min unload speed
  };

  #####################################################################
  #   LED Settings
  #####################################################################
  leds = {
    chamber = {
      count = 144; # SK6812 LED strip
      color_order = "GRBW"; # SK6812 has RGBW with GRB order
      idle_color = {
        r = "0.1";
        g = "0.1";
        b = "0.1";
        w = "0.0";
      };
    };
    toolhead = {
      count = 3; # A4T has 3 neopixels
      color_order = "GRBW";
    };
    hbb = {
      count = 4;
      color_order = "GRB";
    };
  };

in
{
  inherit
    dimensions
    motors
    mcus
    speeds
    kinematics
    movement
    retraction
    purge
    probe
    bed_mesh
    qgl
    heaters
    filament
    leds
    pins
    ;

  # Helper function to get motor config easily
  getMotorXY = motors.xy;
  getMotorZ = motors.z;
  getMotorExtruder = motors.extruder;
}
