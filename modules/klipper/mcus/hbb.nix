{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pinLib = import ../lib/pins.nix { inherit lib; };
  inherit (pinLib) mkPins;

  mcuName = "HBB";

  #####################################################################
  #   BTT HBB (Hot-key Button Board) Pin Definitions
  #
  #   RP2040-based USB board with buttons and RGB LEDs
  #####################################################################
  pinDefs = mkPins "HBB" {
    # Buttons
    button = {
      key1 = { pin = "gpio25"; alias = "KEY1"; };
      key2 = { pin = "gpio26"; alias = "KEY2"; };
      key3 = { pin = "gpio27"; alias = "KEY3"; };
      key4 = { pin = "gpio28"; alias = "KEY4"; };
    };

    # LEDs (WS2812)
    led = { pin = "gpio29"; alias = "LED"; };
  };

  # Extract pins and aliases from the generated definitions
  inherit (pinDefs) pins raw aliases;

  #####################################################################
  #   BTT HBB Firmware Configuration
  #   
  #   RP2040 MCU
  #   USB serial communication
  #   16KiB Katapult bootloader
  #####################################################################
  mcuChip = "RP2040";

  # Common config shared between katapult and klipper
  archConfig = {
    CONFIG_LOW_LEVEL_OPTIONS = "y";
    CONFIG_MACH_RPXXXX = "y";
    CONFIG_MACH_RP2040 = "y";
  };
  
  usbConfig = {
    CONFIG_RPXXXX_USB = "y";
    CONFIG_USBSERIAL = "y";
    CONFIG_USB = "y";
    CONFIG_USB_VENDOR_ID = "0x1d50";
    CONFIG_USB_SERIAL_NUMBER_CHIPID = "n";
    CONFIG_USB_SERIAL_NUMBER = ''"hbb"'';
  };

  firmware = {
    katapult = archConfig // usbConfig // {
      # Katapult at flash start, app at 16KiB offset
      CONFIG_RPXXXX_FLASH_START_0100 = "y";  # RP2040 uses 0100 for "no deployer"
      CONFIG_LAUNCH_APP_ADDRESS = "0x10004000";
      
      # Katapult USB device ID
      CONFIG_USB_DEVICE_ID = "0x6177";
      
      # Double-click reset to enter bootloader
      CONFIG_ENABLE_DOUBLE_RESET = "y";
    };
    
    klipper = archConfig // usbConfig // {
      # Klipper at 16KiB offset (after katapult bootloader)
      CONFIG_RPXXXX_HAVE_BOOTLOADER = "y";
      CONFIG_RPXXXX_FLASH_START_4000 = "y";
      
      # Klipper USB device ID
      CONFIG_USB_DEVICE_ID = "0x614e";
    };
  };

in {
  #####################################################################
  #   MCU: BTT HBB (Hot-key Button Board)
  #   
  #   Hot-key buttons and LEDs on USB RP2040 MCU
  #####################################################################
  
  "mcu ${mcuName}" = {
    serial = config.mcus.hbb.serial;
    restart_method = "command";
    is_critical = false;
  };

  #####################################################################
  #   HBB Buttons
  #####################################################################
  
  "gcode_button hbb_key1" = {
    pin = pins.button.key1;
    press_gcode = "";
    release_gcode = ''
      G28 X
      SET_LED LED=hbb_led RED=1 GREEN=0 BLUE=0 INDEX=1
    '';
  };

  "gcode_button hbb_key2" = {
    pin = pins.button.key2;
    press_gcode = "";
    release_gcode = ''
      G28 Y
      SET_LED LED=hbb_led RED=0 GREEN=1 BLUE=0 INDEX=2
    '';
  };

  "gcode_button hbb_key3" = {
    pin = pins.button.key3;
    press_gcode = "";
    release_gcode = ''
      G28 Z
      SET_LED LED=hbb_led RED=0 GREEN=0 BLUE=1 INDEX=3
    '';
  };

  "gcode_button hbb_key4" = {
    pin = pins.button.key4;
    press_gcode = "";
    release_gcode = ''
      QUAD_GANTRY_LEVEL
      SET_LED LED=hbb_led RED=1 GREEN=1 BLUE=1 INDEX=4
    '';
  };

  #####################################################################
  #   HBB LEDs
  #####################################################################
  
  "neopixel hbb_led" = {
    pin = pins.led;
    chain_count = config.leds.hbb.count;
    color_order = config.leds.hbb.color_order;
    initial_RED = "0.2";
    initial_GREEN = "0.2";
    initial_BLUE = "0.2";
  };

  #####################################################################
  #   Export pins and firmware for use by other modules
  #####################################################################
  _meta = {
    inherit pins firmware aliases mcuName mcuChip;
    rawPins = raw;
  };
}
