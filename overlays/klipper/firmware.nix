# Klipper and Katapult firmware builder overlay
#
# Provides packages for building MCU firmware with Nix.
# Usage:
#   klipper-firmware.override { mcu = "chamber"; firmwareConfig = ./config; }
#   katapult-firmware.override { mcu = "chamber"; firmwareConfig = ./config; }
final: prev: {
  #####################################################################
  #   Klipper Firmware Builder
  #
  #   Custom klipper-firmware package that uses `make olddefconfig`
  #   instead of `make menuconfig` to properly preserve choice options
  #   like clock reference settings.
  #####################################################################

  klipper-firmware =
    {
      mcu ? "mcu",
      firmwareConfig ? null,
      klipper ? null, # Ignored - kept for backwards compatibility
    }:
    assert firmwareConfig != null;
    final.stdenv.mkDerivation {
      pname = "klipper-firmware-${mcu}";
      version = final.klipper.version;
      src = final.klipper-src;

      # klipper-src unpacks as klipper-src-camshaft/
      sourceRoot = "klipper-src-camshaft";

      nativeBuildInputs = with final; [
        python3
        pkgsCross.avr.stdenv.cc
        gcc-arm-embedded
        bintools-unwrapped
        libffi
        libusb1
        pkg-config
        wxGTK32
      ];

      configurePhase = ''
        runHook preConfigure

        cp ${firmwareConfig} ./.config
        chmod +w ./.config

        # Run olddefconfig to fill in missing values without overriding choices
        make olddefconfig

        runHook postConfigure
      '';

      postPatch = ''
        patchShebangs .
      '';

      makeFlags = [ "V=1" ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp ./.config $out/config
        cp out/klipper.bin $out/ || true
        cp out/klipper.elf $out/ || true
        cp out/klipper.uf2 $out/ || true

        runHook postInstall
      '';

      dontFixup = true;

      meta = {
        description = "Klipper firmware for ${mcu}";
        license = final.lib.licenses.gpl3;
        platforms = final.lib.platforms.linux;
      };
    };

  #####################################################################
  #   Katapult Firmware Builder
  #
  #   Similar to klipper-firmware, builds katapult bootloader for MCUs.
  #####################################################################

  katapult-firmware =
    {
      mcu ? "mcu",
      firmwareConfig ? null,
      katapult-pkg ? final.katapult,
    }:
    assert firmwareConfig != null;
    final.stdenv.mkDerivation {
      pname = "katapult-firmware-${mcu}";
      version = katapult-pkg.version;
      src = katapult-pkg.passthru.src;

      nativeBuildInputs = with final; [
        python3
        pkgsCross.avr.stdenv.cc
        gcc-arm-embedded
        bintools-unwrapped
        libffi
        libusb1
        pkg-config
      ];

      configurePhase = ''
        runHook preConfigure

        cp ${firmwareConfig} ./.config
        chmod +w ./.config

        # Run olddefconfig to fill in any missing values
        make olddefconfig

        runHook postConfigure
      '';

      postPatch = ''
        patchShebangs .
      '';

      makeFlags = [ "V=1" ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp ./.config $out/config
        cp out/katapult.bin $out/ || true
        cp out/katapult.elf $out/ || true
        cp out/katapult.uf2 $out/ || true
        cp out/deployer.bin $out/ || true

        runHook postInstall
      '';

      dontFixup = true;

      meta = {
        description = "Katapult bootloader firmware for ${mcu}";
        license = final.lib.licenses.gpl3;
        platforms = final.lib.platforms.linux;
      };
    };
}
