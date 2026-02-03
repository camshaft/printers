{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pinLib = import ../lib/pins.nix { inherit lib; };
  inherit (pinLib) mkPins inv;

  mcuName = "chamber";

  #####################################################################
  #   Raspberry Pi Pico 2 (RP2350) Pin Definitions
  #
  #   Chamber controller for LED strip and door sensor
  #####################################################################
  pinDefs = mkPins mcuName {
    # LED strip data pin (directly on GPIO, no inversion)
    led = { pin = "gpio0"; alias = "LED"; };

    # Door sensor pin with pull-up
    # Microswitch V-156-1C25: SPDT with NC/NO contacts
    # Wire the NC (normally closed) contact so:
    #   - Door closed = switch closed = pin pulled to GND = LOW
    #   - Door open = switch open = pin pulled HIGH by internal pull-up
    door = { pin = "gpio1"; alias = "DOOR"; };
  };

  # Extract pins and aliases from the generated definitions
  inherit (pinDefs) pins raw aliases;

  #####################################################################
  #   Raspberry Pi Pico 2 (RP2350) Firmware Configuration
  #   
  #   USB serial communication
  #   16KiB Katapult bootloader at flash start, Klipper at 0x10004000
  #####################################################################

  mcuChip = "RP2350";

  # Common config shared between katapult and klipper
  archConfig = {
    CONFIG_LOW_LEVEL_OPTIONS = "y";
    CONFIG_MACH_RPXXXX = "y";
    CONFIG_MACH_RP2350 = "y";
  };
  
  usbConfig = {
    CONFIG_RPXXXX_USB = "y";
    CONFIG_USBSERIAL = "y";
    CONFIG_USB = "y";
    CONFIG_USB_VENDOR_ID = "0x1d50";
    CONFIG_USB_SERIAL_NUMBER_CHIPID = "n";
    CONFIG_USB_SERIAL_NUMBER = ''"chamber"'';
  };
  
  firmware = {
    katapult = archConfig // usbConfig // {
      # Katapult at flash start (0x10000000), launches app at 16KiB offset
      CONFIG_RPXXXX_FLASH_START_0000 = "y";
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
  #   MCU: Raspberry Pi Pico 2 (RP2350) - Chamber Controller
  #   
  #   Handles: LED strip, door sensor
  #   Communication: USB Serial (RP2350 doesn't support CAN natively)
  #####################################################################
  
  "mcu ${mcuName}" = {
    serial = config.mcus.chamber.serial;
    restart_method = "command";
    is_critical = false;
  };

  #####################################################################
  #   Door Sensor - Microswitch V-156-1C25 (SPDT)
  #
  #   Wiring: NC contact between GPIO and GND
  #   - Door closed: switch closed, pin LOW (grounded)
  #   - Door open: switch open, pin HIGH (internal pull-up)
  #
  #   Using ^gpio1 enables internal pull-up resistor
  #   "press" = pin goes HIGH = door opened
  #   "release" = pin goes LOW = door closed
  #####################################################################
  
  "gcode_button door_sensor" = {
    pin = "^${pins.door}"; # Enable internal pull-up
    press_gcode = ''
      _DOOR_OPENED
    '';
    release_gcode = ''
      _DOOR_CLOSED
    '';
  };

  #####################################################################
  #   Chamber LED Strip - SK6812 RGBW (144 LEDs)
  #####################################################################
  
  "neopixel chamber_lights" = {
    pin = pins.led;
    chain_count = config.leds.chamber.count;
    color_order = config.leds.chamber.color_order;
    initial_RED = "0.0";
    initial_GREEN = "0.0";
    initial_BLUE = "0.0";
    initial_WHITE = "0.0";
  };

  #####################################################################
  #   Export pins and firmware for use by other modules
  #####################################################################
  _meta = {
    inherit pins firmware aliases mcuName mcuChip;
    rawPins = raw;
  };
}
