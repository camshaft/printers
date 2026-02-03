# Klipper overlay composition
#
# This module composes all Klipper-related overlays into a single overlay
# that can be applied to nixpkgs.
#
# Usage in flake.nix:
#   klipperOverlay = import ./overlays/klipper { inherit klipper-src ...; };
{
  klipper-src,
  cartographer-klipper,
  klipper-led-effect,
  klipper-tmc-autotune,
  klippain-shaketune,
  klipperscreen,
  katapult,
}:
let
  # Patches directory - use path relative to this file
  patchesDir = ../patches;

  # Import individual overlay modules
  klipperOverlay = import ./klipper.nix {
    inherit klipper-src cartographer-klipper klipper-led-effect klipper-tmc-autotune patchesDir;
  };

  pluginsOverlay = import ./plugins.nix {
    inherit cartographer-klipper klipper-led-effect klipper-tmc-autotune klippain-shaketune;
  };

  firmwareOverlay = import ./firmware.nix;

  katapultOverlay = import ./katapult.nix {
    inherit katapult;
  };

  klipperscreenOverlay = import ./klipperscreen.nix {
    inherit klipperscreen;
  };
in
# Compose all overlays into one
final: prev:
let
  # Apply each overlay in sequence
  withKlipper = klipperOverlay final prev;
  withPlugins = pluginsOverlay final (prev // withKlipper);
  withFirmware = firmwareOverlay final (prev // withKlipper // withPlugins);
  withKatapult = katapultOverlay final (prev // withKlipper // withPlugins // withFirmware);
  withKlipperscreen = klipperscreenOverlay final (prev // withKlipper // withPlugins // withFirmware // withKatapult);
in
withKlipper // withPlugins // withFirmware // withKatapult // withKlipperscreen
