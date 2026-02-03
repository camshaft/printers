# Klipper overlay - Pinned Klipper with patches and plugins
#
# This overlay creates a patched klipper source that can be used by both
# the klipper package and firmware builds. Plugins are symlinked flat into
# extras/ following each plugin's install.sh pattern.
{
  klipper-src,
  cartographer-klipper,
  klipper-led-effect,
  klipper-tmc-autotune,
  patchesDir,
}:
final: prev: {
  #####################################################################
  #   Klipper Source - Patched
  #
  #   A derivation that applies our patches to mainline klipper source.
  #   Used by both klipper (host software) and klipper-firmware (MCU).
  #####################################################################

  klipper-src = final.stdenv.mkDerivation {
    pname = "klipper-src";
    version = "camshaft";
    src = klipper-src;

    patches = [
      "${patchesDir}/001-non-critical-mcu.patch"
      "${patchesDir}/002-neopixel-chain-size.patch"
      "${patchesDir}/003-set-led-count.patch"
    ];

    # Copy patched source to output
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      cp -r . $out
      runHook postInstall
    '';
  };

  #####################################################################
  #   Klipper - Host Software with Plugins
  #####################################################################

  klipper = prev.klipper.overrideAttrs (oldAttrs: {
    version = "camshaft";
    src = final.klipper-src;

    # When unpacking a derivation directory, it becomes <name>/contents
    # Override sourceRoot to match: klipper-src-camshaft/klippy
    sourceRoot = "klipper-src-camshaft/klippy";

    # Symlink plugin files flat into extras/ (matching install.sh patterns)
    postInstall = (oldAttrs.postInstall or "") + ''
      extras=$out/lib/klipper/extras

      # Cartographer probe support
      # From install.sh: ln -s idm.py cartographer.py scanner.py
      # Note: Cartographer uses lowercase "probe" command which newer Klipper
      # rejects. We copy and patch the file to use uppercase "PROBE".
      cp -v "${cartographer-klipper}/cartographer.py" "$extras/"
      chmod +w "$extras/cartographer.py"
      sed -i 's/register_command("probe"/register_command("PROBE"/' "$extras/cartographer.py"
      ln -sv "${cartographer-klipper}/scanner.py" "$extras/"
      ln -sv "${cartographer-klipper}/idm.py" "$extras/"

      # LED effects plugin  
      # From install.sh: ln -sf src/led_effect.py
      ln -sv "${klipper-led-effect}/src/led_effect.py" "$extras/"

      # TMC autotune plugin
      # From install.sh: ln -s autotune_tmc.py motor_constants.py motor_database.cfg
      ln -sv "${klipper-tmc-autotune}/autotune_tmc.py" "$extras/"
      ln -sv "${klipper-tmc-autotune}/motor_constants.py" "$extras/"
      ln -sv "${klipper-tmc-autotune}/motor_database.cfg" "$extras/"

      # Note: Klippain ShakeTune requires more complex setup (submodules)
      # and is disabled until proper packaging is implemented.
    '';
  });
}
