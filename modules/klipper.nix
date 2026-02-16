{
  lib,
  pkgs,
  ...
}: let
  #####################################################################
  #   Klipper Configuration
  #
  #   Organized structure:
  #     config.nix    - Common configuration values (MCU UUIDs, etc.)
  #     mcus/         - MCU definitions with colocated pins & firmware
  #     outputs/      - Steppers, heaters, fans, LEDs
  #     sensors/      - Temperature, filament sensors
  #     features/     - Printer settings, bed mesh, input shaper
  #     macros/       - G-code macros (one file per macro group)
  #
  #   Config files are automatically discovered and loaded from each
  #   directory. No need to manually add new files to a list.
  #
  #   Klipper version is pinned via the klipper flake input.
  #   Plugins are installed via the klipper flake's plugin system.
  #####################################################################
  klipperFormat = pkgs.klipperFormat;

  # Generate the immutable config file in the nix store
  immutableConfigFile = klipperFormat.generate "klipper-nix.cfg" klipperSettings;

  # Explicit directory references to ensure they're included in the flake
  # builtins.readDir is used to auto-discover files within each directory
  mcusDir = ./klipper/mcus;
  outputsDir = ./klipper/outputs;
  sensorsDir = ./klipper/sensors;
  featuresDir = ./klipper/features;
  macrosDir = ./klipper/macros;

  # Helper to list all .nix files in a directory
  nixFilesInDir = dir: let
    contents = builtins.readDir dir;
    nixFiles =
      lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "config.nix"
      )
      contents;
  in
    map (name: dir + "/${name}") (builtins.attrNames nixFiles);

  # Auto-discover config files from directories
  mcuFiles = nixFilesInDir mcusDir;
  outputFiles = nixFilesInDir outputsDir;
  sensorFiles = nixFilesInDir sensorsDir;
  featureFiles = nixFilesInDir featuresDir;
  macroFiles = nixFilesInDir macrosDir;

  # Combine all config files
  allConfigFiles = mcuFiles ++ outputFiles ++ sensorFiles ++ featureFiles ++ macroFiles;

  # Import each config file with full result (including _meta)
  importConfigFull = path: (import path) {inherit lib;};

  # Import each config file and merge the results
  # Filter out _meta attributes which are for internal use only
  importConfig = path: let
    imported = importConfigFull path;
  in
    lib.filterAttrs (name: _: name != "_meta") imported;

  configs = map importConfig allConfigFiles;
  klipperSettings = lib.foldl' lib.recursiveUpdate {} configs;

  #####################################################################
  #   MCU Firmware Configuration Extraction
  #
  #   Extract firmware configs from MCU _meta sections to generate
  #   firmware packages without maintaining separate config files.
  #####################################################################

  # Import all MCU files and extract their _meta sections
  mcuConfigs = map importConfigFull mcuFiles;

  # Get _meta from each MCU config (filter out those without firmware)
  mcuMetas = lib.filter (m: m ? firmware && m ? mcuName) (map (c: c._meta or {}) mcuConfigs);

  # Generate menuconfig file content from an attrset
  mkMenuConfig = menuconfig:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name}=${value}") menuconfig) + "\n";

  # Build a klipper firmware package for an MCU
  mkKlipperFirmware = mcuMeta: let
    firmwareConfig = mcuMeta.firmware.klipper or null;
  in
    if firmwareConfig != null
    then
      pkgs.klipper-firmware {
        mcu = mcuMeta.mcuName;
        firmwareConfig = pkgs.writeText "${mcuMeta.mcuName}-klipper.config" (mkMenuConfig firmwareConfig);
      }
    else null;

  # Build a katapult firmware package for an MCU
  mkKatapultFirmware = mcuMeta: let
    firmwareConfig = mcuMeta.firmware.katapult or null;
  in
    if firmwareConfig != null
    then
      pkgs.katapult-firmware {
        mcu = mcuMeta.mcuName;
        firmwareConfig = pkgs.writeText "${mcuMeta.mcuName}-katapult.config" (mkMenuConfig firmwareConfig);
      }
    else null;

  # Build all klipper firmwares as an attrset { mcuName = derivation; }
  klipperFirmwares = lib.listToAttrs (
    lib.filter (x: x.value != null) (
      map (m: {
        name = m.mcuName;
        value = mkKlipperFirmware m;
      })
      mcuMetas
    )
  );

  # Build all katapult firmwares as an attrset { mcuName = derivation; }
  katapultFirmwares = lib.listToAttrs (
    lib.filter (x: x.value != null) (
      map (m: {
        name = m.mcuName;
        value = mkKatapultFirmware m;
      })
      mcuMetas
    )
  );
in {
  #####################################################################
  #   MCU Firmware Packages Option
  #
  #   All MCU firmwares are built as Nix derivations. Access via:
  #     nix build .#nixosConfigurations.<host>.config.klipper.firmwares.klipper.<mcu>
  #     nix build .#nixosConfigurations.<host>.config.klipper.firmwares.katapult.<mcu>
  #
  #   Firmwares are also symlinked at runtime to:
  #     /run/klipper-firmware/klipper/<mcu>.{bin,uf2}
  #     /run/klipper-firmware/katapult/<mcu>.{bin,uf2}
  #####################################################################

  options.klipper.firmwares = {
    klipper = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = klipperFirmwares;
      description = "Klipper MCU firmware packages";
      readOnly = true;
    };

    katapult = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = katapultFirmwares;
      description = "Katapult bootloader firmware packages";
      readOnly = true;
    };
  };

  options.klipper.configFile = lib.mkOption {
    type = lib.types.path;
    default = immutableConfigFile;
    description = "Path to the immutable Nix-generated Klipper config file";
    readOnly = true;
  };

  config = {
    # Klipper scripts (canbus_query, flash_can, etc.) and katapult tools
    environment.systemPackages = [
      pkgs.klippy
      pkgs.katapult-scripts
      pkgs.can-utils
    ];

    # Load CAN kernel modules
    boot.kernelModules = [
      "can"
      "can_raw"
      "can_dev"
    ];

    #####################################################################
    #   MCU Firmware Symlinks
    #
    #   Symlinks to firmware binaries at well-known paths for easy access.
    #   Paths:
    #     /run/klipper-firmware/klipper/<mcu>.bin
    #     /run/klipper-firmware/katapult/<mcu>.bin
    #
    #   Usage:
    #     katapult-flash -d /dev/serial/by-id/... -f /run/klipper-firmware/klipper/chamber.bin
    #####################################################################

    systemd.tmpfiles.rules = let
      # Generate symlink rules for klipper firmwares (uses klipper.bin)
      mkKlipperLinks = firmwares:
        lib.flatten (
          lib.mapAttrsToList (name: pkg: [
            "d /run/klipper-firmware/klipper 0755 root root -"
            "L+ /run/klipper-firmware/klipper/${name}.bin - - - - ${pkg}/klipper.bin"
            "L+ /run/klipper-firmware/klipper/${name}.uf2 - - - - ${pkg}/klipper.uf2"
          ])
          firmwares
        );

      # Generate symlink rules for katapult firmwares
      mkKatapultLinks = firmwares:
        lib.flatten (
          lib.mapAttrsToList (name: pkg: [
            "d /run/klipper-firmware/katapult 0755 root root -"
            "L+ /run/klipper-firmware/katapult/${name}.bin - - - - ${pkg}/katapult.bin"
            "L+ /run/klipper-firmware/katapult/${name}.uf2 - - - - ${pkg}/katapult.uf2"
          ])
          firmwares
        );
    in
      ["d /run/klipper-firmware 0755 root root -"]
      ++ (mkKlipperLinks klipperFirmwares)
      ++ (mkKatapultLinks katapultFirmwares);

    #####################################################################
    #   Klipper Service Configuration
    #
    #   Uses mutableConfig to allow Klipper to make SAVE_CONFIG edits
    #   while the main configuration is versioned in the Nix store.
    #
    #   printer.cfg includes a symlink that points to the current
    #   Nix-generated config. The symlink is updated on each deployment,
    #   allowing config updates without modifying the mutable printer.cfg.
    #####################################################################

    # Symlink updated on each deployment to point to current config
    environment.etc."klipper.cfg".source = immutableConfigFile;

    services.klipper = {
      enable = true;
      mutableConfig = true;
      configFile = pkgs.writeText "printer.cfg" ''
        # Klipper Configuration
        #
        # This file includes the Nix-generated immutable configuration
        # via a symlink that updates on each deployment.
        # Runtime modifications (SAVE_CONFIG) are stored below.
        # To update the main config, edit the Nix files and rebuild.

        [include /etc/klipper.cfg]
      '';
      logFile = "/var/log/journald"; # Log to journald for better integration with system logs
      user = "klipper";
      group = "klipper";
    };

    #####################################################################
    #   Klipper Host MCU Service
    #
    #   Runs klipper_mcu process to expose host GPIO to klipper.
    #   Uses the klipper flake's host-mcu NixOS module which builds
    #   the firmware and manages the systemd service.
    #   Creates /tmp/klipper_host_mcu socket for communication.
    #####################################################################

    services.klipper-mcu.enable = true;

    #####################################################################
    #   Klipper Users & Groups
    #
    #   Plugins are installed via the klipper flake's plugin system
    #   rather than Klipper's update_manager to ensure reproducibility.
    #####################################################################

    users.groups.klipper = {};

    # Note: /gcodes directory is created by nvme.nix module
    # If not using NVMe, uncomment the following:
    # systemd.tmpfiles.rules = [ "d /gcodes 0775 klipper klipper -" ];

    users.users.klipper = {
      isNormalUser = true;
      group = "klipper";
      home = "/var/lib/klipper";
      createHome = true;
      extraGroups = [
        "dialout"
        "tty"
      ];
    };
  };
}
