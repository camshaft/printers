{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
in {
  #####################################################################
  #   Printer Configuration
  #####################################################################

  printer = {
    kinematics = config.kinematics.type;
    max_velocity = config.kinematics.max_velocity;
    max_accel = config.kinematics.max_accel;
    max_z_velocity = config.kinematics.max_z_velocity;
    max_z_accel = config.kinematics.max_z_accel;
    square_corner_velocity = toString config.kinematics.square_corner_velocity;
  };

  #####################################################################
  #   Cartographer V3 Probe
  #####################################################################

  cartographer = {
    mcu = "cartographer";
    x_offset = config.probe.x_offset;
    y_offset = config.probe.y_offset;
  };

  #####################################################################
  #   Safe Z Home
  #####################################################################

  safe_z_home = {
    home_xy_position = "${toString config.dimensions.home_x}, ${toString config.dimensions.home_y}";
    speed = 100;
    z_hop = 10;
  };

  #####################################################################
  #   Quad Gantry Level
  #####################################################################

  quad_gantry_level = {
    gantry_corners = config.qgl.gantry_corners;
    points = config.qgl.points;
    speed = config.speeds.qgl;
    horizontal_move_z = 5;
    retries = 5;
    retry_tolerance = "0.0075";
    max_adjust = 10;
  };

  #####################################################################
  #   Bed Mesh
  #####################################################################

  bed_mesh = {
    speed = config.speeds.bed_mesh;
    horizontal_move_z = 3;
    mesh_min = config.bed_mesh.mesh_min;
    mesh_max = config.bed_mesh.mesh_max;
    probe_count = config.bed_mesh.probe_count;
    algorithm = "bicubic";
    zero_reference_position = config.bed_mesh.zero_reference;
    adaptive_margin = config.bed_mesh.adaptive_margin;
    mesh_pps = "0, 0";  # Disable interpolation - Cartographer mesh is dense enough
  };

  #####################################################################
  #   Input Shaper
  #####################################################################

  input_shaper = {
    # Run SHAPER_CALIBRATE to determine optimal values
    # These are placeholders
    shaper_freq_x = "50";
    shaper_freq_y = "50";
    shaper_type = "mzv";
  };

  #####################################################################
  #   Resonance Tester
  #####################################################################

  resonance_tester = {
    accel_chip = "adxl345";
    probe_points = "${toString config.dimensions.home_x}, ${toString config.dimensions.home_y}, 20";
  };

  #####################################################################
  #   Idle Timeout
  #####################################################################

  idle_timeout = {
    timeout = 1800;  # 30 minutes
  };
}
