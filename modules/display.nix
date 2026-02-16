{
  pkgs,
  lib,
  ...
}: {
  #####################################################################
  #   HDMI Display Configuration
  #
  #   Display: HDMI 5 1.2 (800x480 touchscreen)
  #
  #   Settings from manual:
  #     hdmi_group=2 (DMT mode)
  #     hdmi_mode=87 (custom mode)
  #     hdmi_cvt=800 480 60 6 0 0 0
  #     hdmi_drive=1 (DVI mode - no audio over HDMI)
  #####################################################################

  # Raspberry Pi config.txt settings for HDMI display
  hardware.raspberry-pi.config = {
    all = {
      base-dt-params = {
        # Enable I2C for touchscreen
        i2c_arm = {
          enable = true;
          value = "on";
        };
      };

      options = {
        # HDMI display settings
        hdmi_group = {
          enable = true;
          value = 2; # DMT mode
        };
        hdmi_mode = {
          enable = true;
          value = 87; # Custom mode (use hdmi_cvt)
        };
        hdmi_cvt = {
          enable = true;
          value = "800 480 60 6 0 0 0"; # 800x480 @ 60Hz
        };
        hdmi_drive = {
          enable = true;
          value = 1; # DVI mode
        };

        # Force HDMI output even without display detection
        hdmi_force_hotplug = {
          enable = true;
          value = 1;
        };

        # Disable overscan (already default, but be explicit)
        disable_overscan = {
          enable = true;
          value = true;
        };
      };
    };
  };

  #####################################################################
  #   Audio Configuration
  #
  #   Use HDMI as default audio output
  #####################################################################

  # Enable sound
  services.pulseaudio.enable = false; # Use PipeWire instead
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true;

    # Set HDMI as default audio output
    extraConfig.pipewire = {
      "10-default-sink" = {
        "context.properties" = {
          "default.audio.sink" = "alsa_output.platform-bcm2835_audio.stereo-fallback";
        };
      };
    };
  };

  #####################################################################
  #   KlipperScreen Kiosk Mode
  #
  #   Using cage (Wayland kiosk compositor) for a simple kiosk setup.
  #   This avoids LightDM complexity and runs KlipperScreen directly.
  #####################################################################

  # Enable graphics
  hardware.graphics.enable = true;

  # Cage kiosk compositor service
  services.cage = {
    enable = true;

    environment = {
      WLR_LIBINPUT_NO_DEVICES = "1"; # Don't fail if no input devices
      GTK_CSD = "0"; # Disable client-side decorations
    };

    extraArguments = ["-d"]; # Run in fullscreen/kiosk mode without decorations
    program = "${pkgs.klipperscreen}/bin/KlipperScreen";
    user = "klipper";
  };

  # Prevent getty from starting on tty1 (cage uses it)
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # KlipperScreen package and utilities
  environment.systemPackages = with pkgs; [
    cage
    klipperscreen
    wlr-randr # Wayland display configuration
  ];

  # Allow klipper user to access display
  users.users.klipper.extraGroups = lib.mkAfter [
    "video"
    "input"
    "audio"
  ];

  # Disable screen blanking at console level
  boot.kernelParams = [
    "consoleblank=0"
  ];
}
