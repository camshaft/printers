{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pinLib = import ../lib/pins.nix { inherit lib; };
  inherit (pinLib) mkPins inv;

  mcuName = "EBB";

  #####################################################################
  #   BTT EBB36 Gen2 Pin Definitions
  #
  #   Define pins once with aliases - mkPins generates:
  #   - pins: MCU-prefixed for use in config (e.g., "EBB:PB14")
  #   - raw: just pin values for board_pins
  #   - aliases: auto-generated alias string
  #####################################################################
  pinDefs = mkPins "EBB" {
    # Extruder stepper
    extruder = {
      step = { pin = "PB14"; alias = "E_STEP"; };
      dir = { pin = "PA8"; alias = "E_DIR"; };
      enable = { pin = inv "PB6"; alias = "E_EN"; };
      uart = { pin = "PB3"; alias = "E_UART"; };
    };

    # Heater
    heater = { pin = "PB4"; alias = "HOTEND"; };

    # Thermistor
    thermistor = { pin = "PA3"; alias = "TH0"; };

    # Board temperature sensor (no alias - internal use)
    board_temp = "PA0";

    # Fans
    fan = {
      part = { pin = "PD3"; alias = "PART_FAN"; };
      hotend = { pin = "PA5"; alias = "HOTEND_FAN"; };
      aux = { pin = "PD2"; alias = "FAN2"; };
    };

    # Endstop / Probe pins
    endstop = { pin = "PA15"; alias = "ENDSTOP"; };
    probe = { pin = "PB8"; alias = "PROBE"; };

    # LEDs
    led = {
      neopixel = { pin = "PC7"; alias = "LED"; };
      status = { pin = "PA13"; alias = "STATUS_LED"; };
    };

    # I2C (no aliases - accessed via pins)
    i2c = {
      sda = { pin = "PA6"; alias = "I2C_SDA"; };
      scl = { pin = "PA7"; alias = "I2C_SCL"; };
    };

    # Accelerometer (LIS2DW)
    accel = {
      cs = { pin = "PB1"; alias = "ACCEL_CS"; };
      miso = { pin = "PB2"; alias = "ACCEL_MISO"; };
      mosi = { pin = "PB11"; alias = "ACCEL_MOSI"; };
      sck = { pin = "PB10"; alias = "ACCEL_SCK"; };
    };
  };

  # Extract pins, rawPins, and aliases from the generated definitions
  inherit (pinDefs) pins raw aliases;

  #####################################################################
  #   BTT EBB36 Gen2 Firmware Configuration
  #   
  #   STM32G0B1 @ 8MHz crystal
  #   CAN bus communication
  #####################################################################
  mcuChip = "STM32G0B1";

  canbus_speed = 1000000;
  
  # Common config shared between katapult and klipper
  archConfig = {
    CONFIG_MACH_STM32 = "y";
    CONFIG_MACH_STM32G0 = "y";
    CONFIG_MACH_STM32G0B1 = "y";
    CONFIG_STM32_CLOCK_REF_8M = "y";
  };
  
  canConfig = {
    CONFIG_CANBUS = "y";
    CONFIG_CANBUS_FREQUENCY = toString canbus_speed;
    CONFIG_STM32_CANBUS_PB12_PB13 = "y";
  };
  
  # 8KiB bootloader offset
  bootloaderOffset = "0x8002000";

  firmware = {
    katapult = archConfig // canConfig // {
      # Katapult at flash start, app at 8KiB offset
      CONFIG_STM32_FLASH_START_0000 = "y";
      CONFIG_LAUNCH_APP_ADDRESS = bootloaderOffset;
      
      # Features
      CONFIG_ENABLE_DOUBLE_RESET = "y";
      CONFIG_ENABLE_LED = "y";
      CONFIG_STATUS_LED_PIN = "PA13";
    };
    
    klipper = archConfig // canConfig // {
      # Klipper at 8KiB offset (after katapult)
      CONFIG_STM32_FLASH_START_2000 = "y";
      CONFIG_FLASH_APPLICATION_ADDRESS = bootloaderOffset;
      
      # Keep hotend fan on at boot for safety
      CONFIG_INITIAL_PINS = "PA0";
    };
  };

in {
  #####################################################################
  #   MCU: BTT EBB36 Gen2
  #   
  #   Toolhead controller on CANBUS
  #####################################################################
  
  "mcu ${mcuName}" = {
    canbus_uuid = config.mcus.ebb36.canbus_uuid;
    is_critical = false; # TODO make this critical once we get things working
  };

  #####################################################################
  #   Board Pin Aliases - EBB36 Gen2
  #####################################################################

  "board_pins ebb36_pins" = {
    mcu = mcuName;
    inherit aliases;
  };

  #####################################################################
  #   EBB36 Temperature Sensor
  #####################################################################
  
  "temperature_sensor EBB36" = {
    sensor_type = "Generic 3950";
    sensor_pin = pins.board_temp;
    pullup_resistor = 2200;
    min_temp = 0;
    max_temp = 100;
  };

  #####################################################################
  #   Accelerometer (LIS2DW on EBB36)
  #####################################################################
  
  "lis2dw toolhead" = {
    cs_pin = pins.accel.cs;
    spi_software_sclk_pin = pins.accel.sck;
    spi_software_mosi_pin = pins.accel.mosi;
    spi_software_miso_pin = pins.accel.miso;
    axes_map = "x,y,z";
  };

  #####################################################################
  #   Export pins and firmware for use by other modules
  #####################################################################
  _meta = {
    inherit pins firmware aliases mcuName mcuChip;
    rawPins = raw;
  };
}
