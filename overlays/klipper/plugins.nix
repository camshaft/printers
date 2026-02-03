# Klipper plugins overlay
#
# Provides Klipper plugin packages that are symlinked into Klipper's extras/.
# These follow each plugin's install.sh pattern for flat symlinks.
{
  cartographer-klipper,
  klipper-led-effect,
  klipper-tmc-autotune,
  klippain-shaketune,
}:
final: prev: {
  #####################################################################
  #   Cartographer Probe Support
  #####################################################################

  klipper-cartographer = final.stdenv.mkDerivation {
    pname = "klipper-cartographer";
    version = "unstable";
    src = cartographer-klipper;
    installPhase = ''
      mkdir -p $out/lib/klipper/extras
      cp -r *.py $out/lib/klipper/extras/ 2>/dev/null || true
      cp -r cartographer*.py $out/lib/klipper/extras/ 2>/dev/null || true
    '';
  };

  #####################################################################
  #   LED Effects Plugin
  #####################################################################

  klipper-led-effect = final.stdenv.mkDerivation {
    pname = "klipper-led-effect";
    version = "unstable";
    src = klipper-led-effect;
    installPhase = ''
      mkdir -p $out/lib/klipper/extras
      cp -r *.py $out/lib/klipper/extras/ 2>/dev/null || true
      cp -r led_effect*.py $out/lib/klipper/extras/ 2>/dev/null || true
    '';
  };

  #####################################################################
  #   TMC Autotune Plugin
  #####################################################################

  klipper-tmc-autotune = final.stdenv.mkDerivation {
    pname = "klipper-tmc-autotune";
    version = "unstable";
    src = klipper-tmc-autotune;
    installPhase = ''
      mkdir -p $out/lib/klipper/extras
      cp -r *.py $out/lib/klipper/extras/ 2>/dev/null || true
    '';
  };

  #####################################################################
  #   Klippain ShakeTune - Resonance Testing
  #####################################################################

  klippain-shaketune = final.python3Packages.buildPythonPackage {
    pname = "klippain-shaketune";
    version = "unstable";
    src = klippain-shaketune;
    format = "other";

    propagatedBuildInputs = with final.python3Packages; [
      numpy
      matplotlib
      scipy
    ];

    installPhase = ''
      mkdir -p $out/lib/klipper/extras
      mkdir -p $out/lib/python/shaketune

      # Install Klipper extras
      if [ -d "shaketune" ]; then
        cp -r shaketune/*.py $out/lib/klipper/extras/ 2>/dev/null || true
      fi

      # Install Python module
      cp -r shaketune/* $out/lib/python/shaketune/ 2>/dev/null || true
    '';
  };

  # Pass through sources for use in klipper override
  klipper-plugin-sources = {
    inherit cartographer-klipper klipper-led-effect klipper-tmc-autotune;
  };
}
