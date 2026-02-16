{
  description = "Printer PI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Klipper
    klipper = {
      url = "github:camshaft/klipper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Klipper plugins
    cartographer-klipper = {
      url = "github:Cartographer3D/cartographer-klipper/master";
      flake = false;
    };

    klipper-led-effect = {
      url = "github:julianschill/klipper-led_effect/master";
      flake = false;
    };

    klipper-tmc-autotune = {
      url = "github:andrewmcgr/klipper_tmc_autotune/main";
      flake = false;
    };

    klippain-shaketune = {
      url = "github:Frix-x/klippain-shaketune/main";
      flake = false;
    };

    klipperscreen = {
      url = "github:KlipperScreen/KlipperScreen/master";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    nixos-generators,
    nixos-hardware,
    nixos-raspberrypi,
    klipper,
    cartographer-klipper,
    klipper-led-effect,
    klipper-tmc-autotune,
    klipperscreen,
    ...
  } @ inputs: let
    # Klipper overlay with plugins
    #
    # Uses klipper.lib.mkOverlay to create an overlay that includes
    # klipper, klipper-firmware, katapult, and all plugins.
    klipperOverlay = klipper.lib.mkOverlay {
      plugins = [
        # Cartographer probe support
        # Patch: Cartographer uses lowercase "probe" command which newer
        # Klipper rejects. Patch it to use uppercase "PROBE".
        {
          name = "cartographer";
          src = cartographer-klipper;
          files = ["cartographer.py" "scanner.py" "idm.py"];
          patches = [
            {
              file = "cartographer.py";
              sed = ''s/register_command("probe"/register_command("PROBE"/'';
            }
          ];
        }
        # LED effects plugin
        {
          name = "led-effect";
          src = klipper-led-effect;
          files = ["src/led_effect.py"];
        }
        # TMC autotune plugin
        {
          name = "tmc-autotune";
          src = klipper-tmc-autotune;
          files = ["autotune_tmc.py" "motor_constants.py" "motor_database.cfg"];
        }
      ];
    };

    # KlipperScreen overlay (not part of the klipper flake)
    klipperscreenOverlay = import ./overlays/klipperscreen.nix {
      inherit klipperscreen;
    };

    # Common overlays for all configurations
    overlays = [klipperOverlay klipperscreenOverlay];

    # Common extra modules for all configurations
    extraModules = [
      klipper.nixosModules.host-mcu
    ];
  in {
    # NixOS configurations for Raspberry Pi 4 and 5
    nixosConfigurations = {
      "printer-pi-4" = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;

        modules = [
          {
            nixpkgs.overlays = overlays;
            imports =
              extraModules
              ++ (with nixos-raspberrypi.nixosModules; [
                raspberry-pi-4.base
                raspberry-pi-4.display-vc4
                raspberry-pi-4.bluetooth
              ]);
          }
          ./configuration.nix
        ];
      };

      "printer-pi-5" = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;

        modules = [
          {
            nixpkgs.overlays = overlays;
            imports =
              extraModules
              ++ (with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.page-size-16k
                raspberry-pi-5.display-vc4
              ]);
          }
          ./configuration.nix
        ];
      };

      # SD card image configurations (for initial installation)
      "printer-pi-4-image" = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;

        modules = [
          {
            nixpkgs.overlays = overlays;
            imports =
              extraModules
              ++ (with nixos-raspberrypi.nixosModules; [
                raspberry-pi-4.base
                raspberry-pi-4.display-vc4
                raspberry-pi-4.bluetooth
                sd-image
              ]);
          }
          ./configuration.nix
        ];
      };

      "printer-pi-5-image" = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;

        modules = [
          {
            nixpkgs.overlays = overlays;
            imports =
              extraModules
              ++ (with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.page-size-16k
                raspberry-pi-5.display-vc4
                sd-image
              ]);
          }
          ./configuration.nix
        ];
      };
    };
  };
}
