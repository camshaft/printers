{pkgs, ...}: {
  #####################################################################
  #   NVMe Storage Configuration
  #
  #   Mounts NVMe drive for gcode storage. The drive is mounted at
  #   /gcodes which is where Klipper's virtual_sdcard looks for files.
  #####################################################################

  # Enable NVMe kernel module
  boot.initrd.availableKernelModules = ["nvme"];

  hardware.raspberry-pi.config = {
    all = {
      base-dt-params = {
        # Enable I2C for touchscreen
        i2c_arm = {
          enable = true;
          value = "on";
        };

        pciex1 = {
          enable = true;
          value = "on";
        };
      };
    };
  };

  # Mount NVMe partition for gcode storage
  fileSystems."/gcodes" = {
    device = "/dev/disk/by-label/GCODES";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail" # Don't fail boot if drive is missing
    ];
  };

  # Ensure the mount point exists and has correct permissions
  systemd.tmpfiles.rules = [
    "d /gcodes 0775 klipper klipper - -"
  ];

  # Set ownership after mount (nofail means drive might not be there)
  systemd.services.gcodes-permissions = {
    description = "Set gcode directory permissions";
    after = ["local-fs.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/chown -R klipper:klipper /gcodes";
    };
    unitConfig = {
      ConditionPathIsMountPoint = "/gcodes";
    };
  };
}
