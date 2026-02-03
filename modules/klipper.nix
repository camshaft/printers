{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  #   Klipper version is pinned via flake.nix overlay.
  #   Plugins are installed via Nix, not update_manager.
  #####################################################################

  #####################################################################
  #   Klipper INI Format with Auto-Indented Multiline Values
  #
  #   Klipper requires multiline values (gcode, aliases, etc.) to:
  #   1. Start on a new line after the key
  #   2. Have each continuation line indented with spaces
  #
  #   Booleans are converted to Python-style True/False.
  #####################################################################

  # Convert values to Klipper-compatible strings (Python bools, etc.)
  mkKlipperValue =
    v:
    if v == true then
      "True"
    else if v == false then
      "False"
    else
      lib.generators.mkValueStringDefault { } v;

  # Format multiline gcode preserving relative indentation
  # Removes common leading whitespace (like Nix's '' strings) but keeps relative indent
  formatMultilineValue =
    str:
    let
      lines = lib.splitString "\n" str;
      # Filter out empty lines for calculating indent, but keep them in output
      nonEmptyLines = lib.filter (l: lib.stringLength (lib.trim l) > 0) lines;
      # Get leading whitespace count for each non-empty line
      getIndent =
        s:
        lib.stringLength s
        - lib.stringLength (
          lib.trimWith {
            start = true;
            end = false;
          } s
        );
      indents = map getIndent nonEmptyLines;
      # Find minimum indent (common prefix to strip)
      minIndent = if indents == [ ] then 0 else lib.foldl' lib.min (lib.head indents) indents;
      # Strip common indent and add base indent for Klipper
      processLine =
        l:
        let
          trimmed = lib.trim l;
        in
        if trimmed == "" then
          ""
        else
          let
            currentIndent = getIndent l;
            relativeIndent = currentIndent - minIndent;
            spaces = lib.concatStrings (lib.genList (_: " ") relativeIndent);
          in
          "  " + spaces + trimmed;
      processedLines = map processLine lines;
      # Remove leading/trailing empty lines
      trimmedLines = lib.filter (l: l != "") processedLines;
    in
    "\n" + lib.concatStringsSep "\n" trimmedLines;

  klipperFormat = pkgs.formats.ini {
    listToValue =
      l:
      if builtins.length l == 1 then
        mkKlipperValue (lib.head l)
      else
        lib.concatMapStrings (s: "\n  ${mkKlipperValue s}") l;
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString =
        v:
        let
          str = mkKlipperValue v;
        in
        # If value contains newlines, format it properly for Klipper
        if lib.hasInfix "\n" str then formatMultilineValue str else str;
    } ":";
  };

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
  nixFilesInDir =
    dir:
    let
      contents = builtins.readDir dir;
      nixFiles = lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "config.nix"
      ) contents;
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
  importConfigFull = path: (import path) { inherit lib; };

  # Import each config file and merge the results
  # Filter out _meta attributes which are for internal use only
  importConfig =
    path:
    let
      imported = importConfigFull path;
    in
    lib.filterAttrs (name: _: name != "_meta") imported;

  configs = map importConfig allConfigFiles;
  klipperSettings = lib.foldl' lib.recursiveUpdate { } configs;

  #####################################################################
  #   MCU Firmware Configuration Extraction
  #
  #   Extract firmware configs from MCU _meta sections to generate
  #   firmware packages without maintaining separate config files.
  #####################################################################

  # Import all MCU files and extract their _meta sections
  mcuConfigs = map importConfigFull mcuFiles;

  # Get _meta from each MCU config (filter out those without firmware)
  mcuMetas = lib.filter (m: m ? firmware && m ? mcuName) (map (c: c._meta or { }) mcuConfigs);

  # Generate menuconfig file content from an attrset
  mkMenuConfig =
    menuconfig:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name}=${value}") menuconfig) + "\n";

  # Build a klipper firmware package for an MCU
  mkKlipperFirmware =
    mcuMeta:
    let
      firmwareConfig = mcuMeta.firmware.klipper or null;
    in
    if firmwareConfig != null then
      pkgs.klipper-firmware {
        klipper = config.services.klipper.package;
        mcu = mcuMeta.mcuName;
        firmwareConfig = pkgs.writeText "${mcuMeta.mcuName}-klipper.config" (mkMenuConfig firmwareConfig);
      }
    else
      null;

  # Build a katapult firmware package for an MCU
  mkKatapultFirmware =
    mcuMeta:
    let
      firmwareConfig = mcuMeta.firmware.katapult or null;
    in
    if firmwareConfig != null then
      pkgs.katapult-firmware {
        mcu = mcuMeta.mcuName;
        firmwareConfig = pkgs.writeText "${mcuMeta.mcuName}-katapult.config" (mkMenuConfig firmwareConfig);
      }
    else
      null;

  # Build all klipper firmwares as an attrset { mcuName = derivation; }
  klipperFirmwares = lib.listToAttrs (
    lib.filter (x: x.value != null) (
      map (m: {
        name = m.mcuName;
        value = mkKlipperFirmware m;
      }) mcuMetas
    )
  );

  # Build all katapult firmwares as an attrset { mcuName = derivation; }
  katapultFirmwares = lib.listToAttrs (
    lib.filter (x: x.value != null) (
      map (m: {
        name = m.mcuName;
        value = mkKatapultFirmware m;
      }) mcuMetas
    )
  );

  # Find the host MCU firmware (special case - runs as a service)
  hostFirmware = klipperFirmwares.host or null;

  #####################################################################
  #   Klipper Scripts with Dependencies
  #
  #   Wrapper scripts for Klipper utilities (canbus_query, flash_usb, etc.)
  #   that include all necessary Python dependencies.
  #####################################################################

  klipperScriptsEnv = pkgs.python3.withPackages (ps: [
    ps.pyserial
    ps.python-can
    ps.packaging
  ]);

  klipperScripts = pkgs.stdenv.mkDerivation {
    pname = "klipper-scripts";
    version = config.services.klipper.package.version;
    dontUnpack = true;
    buildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir -p $out/bin

      # CAN bus query script
      makeWrapper ${klipperScriptsEnv}/bin/python3 $out/bin/klipper-canbus-query \
        --add-flags "${config.services.klipper.package}/lib/scripts/canbus_query.py"

      # Flash CAN script  
      makeWrapper ${klipperScriptsEnv}/bin/python3 $out/bin/klipper-flash-can \
        --add-flags "${config.services.klipper.package}/lib/scripts/flash_can.py"

      # USB flash script
      makeWrapper ${klipperScriptsEnv}/bin/python3 $out/bin/klipper-flash-usb \
        --add-flags "${config.services.klipper.package}/lib/scripts/flash_usb.py"
    '';
  };

in
{
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
    # Add klipper and katapult scripts to system path
    environment.systemPackages = [
      klipperScripts
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

    systemd.tmpfiles.rules =
      let
        # Generate symlink rules for a firmware type
        mkFirmwareLinks =
          type: firmwares:
          lib.flatten (
            lib.mapAttrsToList (name: pkg: [
              # Create directories
              "d /run/klipper-firmware/${type} 0755 root root -"
              # Symlink .bin files
              "L+ /run/klipper-firmware/${type}/${name}.bin - - - - ${pkg}/katapult.bin"
              # Symlink .uf2 files if they exist
              "L+ /run/klipper-firmware/${type}/${name}.uf2 - - - - ${pkg}/katapult.uf2"
            ]) firmwares
          );

        # Generate symlink rules for klipper firmwares (uses klipper.bin)
        mkKlipperLinks =
          firmwares:
          lib.flatten (
            lib.mapAttrsToList (name: pkg: [
              "d /run/klipper-firmware/klipper 0755 root root -"
              "L+ /run/klipper-firmware/klipper/${name}.bin - - - - ${pkg}/klipper.bin"
              "L+ /run/klipper-firmware/klipper/${name}.uf2 - - - - ${pkg}/klipper.uf2"
            ]) firmwares
          );

        # Generate symlink rules for katapult firmwares
        mkKatapultLinks =
          firmwares:
          lib.flatten (
            lib.mapAttrsToList (name: pkg: [
              "d /run/klipper-firmware/katapult 0755 root root -"
              "L+ /run/klipper-firmware/katapult/${name}.bin - - - - ${pkg}/katapult.bin"
              "L+ /run/klipper-firmware/katapult/${name}.uf2 - - - - ${pkg}/katapult.uf2"
            ]) firmwares
          );
      in
      [ "d /run/klipper-firmware 0755 root root -" ]
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
      logFile = "/var/lib/klipper/klipper.log";
      user = "klipper";
      group = "klipper";
    };

    # Logrotate for klipper logs - prevent filling up disk
    services.logrotate.settings.klipper = {
      files = "/var/lib/klipper/klipper.log";
      frequency = "daily";
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      copytruncate = true;
    };

    #####################################################################
    #   Klipper Host MCU Service
    #
    #   Runs klipper_mcu process to expose host GPIO to klipper
    #   Creates /tmp/klipper_host_mcu socket for communication
    #   Firmware config is generated from modules/klipper/mcus/host.nix
    #####################################################################

    systemd.services.klipper-mcu = lib.mkIf (hostFirmware != null) {
      description = "Klipper Host MCU";
      wantedBy = [ "multi-user.target" ];
      before = [ "klipper.service" ];
      serviceConfig = {
        ExecStart = "${hostFirmware}/klipper.elf -r";
        Restart = "always";
        RestartSec = 10;
      };
    };

    #####################################################################
    #   Klipper Plugins
    #
    #   Plugins are installed via Nix as part of the klipper package
    #   (see overlays/klipper.nix) rather than Klipper's update_manager
    #   to ensure reproducibility and version control.
    #####################################################################

    users.groups.klipper = { };

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
