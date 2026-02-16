# Klipper overlay - Pinned Klipper with patches and plugins
#
# This overlay creates a patched klipper source that can be used by both
# the klipper package and firmware builds. Plugins are symlinked flat into
# extras/ following each plugin's install.sh pattern.
#
# The chelper C modules are pre-built with native optimizations for the
# target architecture during the Nix build, rather than being compiled
# on-demand at runtime which would increase boot latency.
{
  klipper-src,
  cartographer-klipper,
  klipper-led-effect,
  klipper-tmc-autotune,
  patchesDir,
}:
final: prev:
let
  # Architecture-specific optimization flags for chelper compilation.
  # These are performance-critical modules for stepper timing calculations.
  chelperCflags =
    if final.stdenv.hostPlatform.isAarch64 then
      # ARM64 (Raspberry Pi 4/5) - use NEON vectorization
      "-march=armv8-a -mtune=cortex-a76 -ftree-vectorize"
    else if final.stdenv.hostPlatform.isAarch32 then
      # ARM32 (older Raspberry Pi)
      "-march=armv7-a -mfpu=neon-vfpv4 -ftree-vectorize"
    else if final.stdenv.hostPlatform.isx86_64 then
      # x86_64 - use SSE2 (baseline for x86_64)
      "-mfpmath=sse -msse2"
    else
      # Fallback - no arch-specific flags
      "";
in
{
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
  #
  #   The chelper C modules are pre-compiled during the Nix build with
  #   native optimizations for the target architecture. This eliminates
  #   the on-demand compilation that would otherwise happen at first
  #   boot, reducing startup latency.
  #####################################################################

  klipper = prev.klipper.overrideAttrs (oldAttrs: {
    version = "camshaft";
    src = final.klipper-src;

    # When unpacking a derivation directory, it becomes <name>/contents
    # Override sourceRoot to match: klipper-src-camshaft/klippy
    sourceRoot = "klipper-src-camshaft/klippy";

    # Patch chelper to use our optimized compilation settings.
    # Note: nixpkgs already substitutes GCC_CMD for cross-compilation support,
    # so we only need to add our optimization flags.
    postPatch = (oldAttrs.postPatch or "") + ''
      # Upgrade from -O2 to -O3 for better optimization of critical code paths
      # and add architecture-specific flags for native performance
      substituteInPlace ./chelper/__init__.py \
        --replace-fail \
          'COMPILE_ARGS = ("-Wall -g -O2 -shared -fPIC"' \
          'COMPILE_ARGS = ("-Wall -g -O3 -shared -fPIC ${chelperCflags}"'
    '';

    # Pre-build the chelper C modules during the Nix build.
    # This is critical for performance - these modules handle stepper timing
    # calculations and benefit significantly from native optimizations.
    postBuild = (oldAttrs.postBuild or "") + ''
      echo "Building chelper with optimizations: ${chelperCflags}"
      python ./chelper/__init__.py
    '';

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
