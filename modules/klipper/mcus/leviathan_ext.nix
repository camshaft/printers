{ lib ? import <nixpkgs/lib>, ... }:
let
  pinLib = import ../lib/pins.nix { inherit lib; };
  inherit (pinLib) mkPins inv;

  #####################################################################
  #   LDO Leviathan Extension Board Pin Definitions
  #
  #   Note: The extension board shares the same MCU as the main
  #   Leviathan. These pins are exported and merged into the main
  #   Leviathan board_pins by leviathan.nix.
  #####################################################################
  pinDefs = mkPins "mcu" {
    # HV Stepper ports on Extension (for AWD motors)
    hv_stepper = {
      s2 = {
        step = { pin = "PD15"; alias = "HV_STEP2"; };
        dir = { pin = "PD14"; alias = "HV_DIR2"; };
        enable = { pin = inv "PG2"; alias = "HV_EN2"; };
        cs = { pin = "PB12"; alias = "HV_CS2"; };
      };
      s3 = {
        step = { pin = "PG4"; alias = "HV_STEP3"; };
        dir = { pin = "PE8"; alias = "HV_DIR3"; };
        enable = { pin = inv "PB0"; alias = "HV_EN3"; };
        cs = { pin = "PG5"; alias = "HV_CS3"; };
      };
    };

    # Additional thermistors
    thermistor = {
      th4 = { pin = "PC4"; alias = "TH4"; };
      th5 = { pin = "PC5"; alias = "TH5"; };
    };

    # Additional fans
    fan = {
      f0 = { pin = "PD12"; alias = "EXT_FAN0"; };
      f1 = { pin = "PD13"; alias = "EXT_FAN1"; };
      f2 = { pin = "PD14"; alias = "EXT_FAN2"; };
      f3 = { pin = "PD15"; alias = "EXT_FAN3"; };
    };

    # Buzzer (passive, PWM)
    buzzer = { pin = "PB1"; alias = "BUZZER"; };

    # SPI2 bus (for extension TMC5160)
    spi2 = {
      miso = { pin = "PC2"; alias = "SPI2_MISO"; };
      mosi = { pin = "PC3"; alias = "SPI2_MOSI"; };
      sck = { pin = "PB13"; alias = "SPI2_SCK"; };
      bus = "spi2";
    };
  };

  # Extract pins and aliases from the generated definitions
  inherit (pinDefs) pins raw aliases;

in {
  #####################################################################
  #   Export pins for use by other modules
  #
  #   No klipper config sections here - the extension shares the main
  #   Leviathan MCU. Pins are merged into leviathan.nix board_pins.
  #####################################################################
  _meta = {
    inherit pins aliases;
    rawPins = raw;
  };
}
