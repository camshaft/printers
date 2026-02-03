{ lib ? import <nixpkgs/lib>, ... }:
let
  config = import ../config.nix { inherit lib; };
  pinLib = import ../lib/pins.nix { inherit lib; };
  inherit (pinLib) mkPins inv;

  mcuName = "leviathan";

  # Import extension board pins (shares same MCU)
  extPins = (import ./leviathan_ext.nix { inherit lib; })._meta;

  #####################################################################
  #   LDO Leviathan V1.3 Pin Definitions
  #####################################################################
  pinDefs = mkPins "mcu" {
    # HV Stepper ports (48V capable TMC5160)
    hv_stepper = {
      s0 = {
        step = { pin = "PB10"; alias = "HV_STEP0"; };
        dir = { pin = "PB11"; alias = "HV_DIR0"; };
        enable = { pin = inv "PG0"; alias = "HV_EN0"; };
        cs = { pin = "PE15"; alias = "HV_CS0"; };
      };
      s1 = {
        step = { pin = "PF15"; alias = "HV_STEP1"; };
        dir = { pin = "PF14"; alias = "HV_DIR1"; };
        enable = { pin = inv "PE9"; alias = "HV_EN1"; };
        cs = { pin = "PE11"; alias = "HV_CS1"; };
      };
    };

    # Standard Stepper ports (TMC2209)
    stepper = {
      s0 = {
        step = { pin = "PD4"; alias = "STEP0"; };
        dir = { pin = "PD3"; alias = "DIR0"; };
        enable = { pin = inv "PD7"; alias = "EN0"; };
        uart = { pin = "PD5"; alias = "UART0"; };
      };
      s1 = {
        step = { pin = "PC12"; alias = "STEP1"; };
        dir = { pin = "PC11"; alias = "DIR1"; };
        enable = { pin = inv "PD2"; alias = "EN1"; };
        uart = { pin = "PD0"; alias = "UART1"; };
      };
      s2 = {
        step = { pin = "PC9"; alias = "STEP2"; };
        dir = { pin = "PC8"; alias = "DIR2"; };
        enable = { pin = inv "PC10"; alias = "EN2"; };
        uart = { pin = "PA8"; alias = "UART2"; };
      };
      s3 = {
        step = { pin = "PG7"; alias = "STEP3"; };
        dir = { pin = "PG6"; alias = "DIR3"; };
        enable = { pin = inv "PC7"; alias = "EN3"; };
        uart = { pin = "PG8"; alias = "UART3"; };
      };
      s4 = {
        step = { pin = "PD10"; alias = "STEP4"; };
        dir = { pin = "PD9"; alias = "DIR4"; };
        enable = { pin = inv "PD13"; alias = "EN4"; };
        uart = { pin = "PD11"; alias = "UART4"; };
      };
    };

    # Endstops
    endstop = {
      x = { pin = "PC1"; alias = "XSTOP"; };
      y = { pin = "PC2"; alias = "YSTOP"; };
      z = { pin = "PC3"; alias = "ZSTOP"; };
    };

    # Thermistors
    thermistor = {
      th0 = { pin = "PA1"; alias = "TH0"; };
      th1 = { pin = "PA2"; alias = "TH1"; };
      th2 = { pin = "PA0"; alias = "TH2"; };
      th3 = { pin = "PA3"; alias = "TH3"; };
    };

    # Heaters
    heater = {
      he0 = { pin = "PG10"; alias = "HE0"; };
      bed = { pin = "PG11"; alias = "HE_BED"; };
    };

    # Fans
    fan = {
      f0 = { pin = "PB7"; alias = "FAN0"; };
      f1 = { pin = "PB6"; alias = "FAN1"; };
      f2 = { pin = "PF7"; alias = "FAN2"; };
      f3 = { pin = "PF9"; alias = "FAN3"; };
      f4 = { pin = "PF6"; alias = "FAN4"; };
      f5 = { pin = "PF8"; alias = "FAN5"; };
    };

    # Probe
    probe = { pin = "PF1"; alias = "PROBE"; };

    # Filament sensor
    filament = {
      detect = { pin = "PC0"; alias = "FIL_DET"; };
      motion = "PG12"; # no alias
    };

    # LED Strip (PWM capable)
    led_strip = { pin = "PE6"; alias = "LED_STRIP"; };

    # SPI4 bus (for TMC5160)
    spi4 = {
      miso = { pin = "PE13"; alias = "SPI4_MISO"; };
      mosi = { pin = "PE14"; alias = "SPI4_MOSI"; };
      sck = { pin = "PE12"; alias = "SPI4_SCK"; };
      bus = "spi4";
    };

    # EXP1 header
    exp1 = {
      pin1 = { pin = "PG9"; alias = "EXP1_1"; };
      pin2 = { pin = "PG12"; alias = "EXP1_2"; };
      pin3 = { pin = "PG13"; alias = "EXP1_3"; };
      pin4 = { pin = "PG14"; alias = "EXP1_4"; };
      pin5 = { pin = "PC13"; alias = "EXP1_5"; };
      pin6 = { pin = "PC14"; alias = "EXP1_6"; };
      pin7 = { pin = "PC15"; alias = "EXP1_7"; };
      pin8 = { pin = "PF0"; alias = "EXP1_8"; };
    };

    # EXP2 header
    exp2 = {
      pin1 = { pin = "PA6"; alias = "EXP2_1"; };
      pin2 = { pin = "PA5"; alias = "EXP2_2"; };
      pin3 = { pin = "PE2"; alias = "EXP2_3"; };
      pin4 = { pin = "PE4"; alias = "EXP2_4"; };
      pin5 = { pin = "PE3"; alias = "EXP2_5"; };
      pin6 = { pin = "PA7"; alias = "EXP2_6"; };
      pin7 = { pin = "PE5"; alias = "EXP2_7"; };
      pin10 = { pin = "PE4"; alias = "EXP2_10"; };
    };
  };

  # Extract pins and aliases from the generated definitions
  inherit (pinDefs) pins raw aliases;

  #####################################################################
  #   LDO Leviathan V1.3 Firmware Configuration
  #   
  #   STM32H743 @ 25MHz crystal
  #   USB-to-CAN bridge mode (katapult via USB, klipper bridges to CAN)
  #####################################################################
  mcuChip = "STM32H743";

  canbus_speed = 1000000;
  
  # Common config shared between katapult and klipper
  archConfig = {
    CONFIG_LOW_LEVEL_OPTIONS = "y";
    CONFIG_MACH_STM32 = "y";
    CONFIG_MACH_STM32H7 = "y";
    CONFIG_MACH_STM32H743 = "y";
    CONFIG_STM32_CLOCK_REF_25M = "y";
  };
  
  usbConfig = {
    CONFIG_USB = "y";
    CONFIG_USB_VENDOR_ID = "0x1d50";
    CONFIG_USB_SERIAL_NUMBER_CHIPID = "n";
    CONFIG_USB_SERIAL_NUMBER = ''"leviathan"'';
  };

  firmware = {
    katapult = archConfig // usbConfig // {
      # Katapult at flash start, app at 128KiB offset
      CONFIG_STM32_FLASH_START_0000 = "y";
      CONFIG_STM32_APP_START_20000 = "y";
      CONFIG_LAUNCH_APP_ADDRESS = "0x8020000";
      
      # Communication: USB serial
      CONFIG_STM32_USB_PA11_PA12 = "y";
      CONFIG_USBSERIAL = "y";
      CONFIG_USB_DEVICE_ID = "0x6177";
      
      # CAN bus speed (for potential CAN flashing)
      CONFIG_CANBUS_FREQUENCY = toString canbus_speed;
      
      # Features
      CONFIG_ENABLE_DOUBLE_RESET = "y";
      CONFIG_ENABLE_LED = "y";
      CONFIG_STATUS_LED_PIN = "PE1";
    };
    
    klipper = archConfig // usbConfig // {
      # Klipper at 128KiB offset (after katapult)
      CONFIG_STM32_FLASH_START_20000 = "y";
      CONFIG_FLASH_APPLICATION_ADDRESS = "0x8020000";
      
      # Communication: USB to CAN bridge
      CONFIG_STM32_USBCANBUS_PA11_PA12 = "y";
      CONFIG_USBCANBUS = "y";
      CONFIG_USB_DEVICE_ID = "0x614e";
      
      # CAN bus on PB8/PB9 (CMENU for bridge mode)
      CONFIG_CANBUS = "y";
      CONFIG_CANBUS_FREQUENCY = toString canbus_speed;
      CONFIG_STM32_CMENU_CANBUS_PB8_PB9 = "y";
      CONFIG_STM32_CANBUS_PB8_PB9 = "y";
    };
  };

in {
  #####################################################################
  #   MCU: LDO Leviathan V1.3
  #
  #   Main controller acting as USB-to-CAN bridge
  #####################################################################

  mcu = {
    canbus_uuid = config.mcus.leviathan.canbus_uuid;
    canbus_interface = config.mcus.leviathan.canbus_interface;
  };

  #####################################################################
  #   Board Pin Aliases - Leviathan V1.3
  #####################################################################

  board_pins = {
    aliases = aliases + ", EXP1_9=<GND>, EXP1_10=<5V>, EXP2_8=<RST>, EXP2_9=<GND>";
  };

  #####################################################################
  #   Export pins and firmware for use by other modules
  #####################################################################
  _meta = {
    inherit pins firmware aliases mcuName mcuChip;
    rawPins = raw;
  };
}
