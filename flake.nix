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

    # Klipper source
    klipper-src = {
      url = "github:Klipper3d/klipper/master";
      flake = false;
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

    # Katapult bootloader for MCU firmware updates
    katapult = {
      url = "github:Arksine/katapult/master";
      flake = false;
    };

    # Camera streamer for webcam streaming
    camera-streamer = {
      url = "github:ayufan/camera-streamer/v0.4.0";
      flake = false;
    };

    # magic_enum submodule for camera-streamer - pinned to commit from .gitmodules
    magic-enum = {
      url = "github:Neargye/magic_enum/48054f64abcfc83f58d9aa2efbbd21604f93aca4";
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

  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      nixos-hardware,
      nixos-raspberrypi,
      klipper-src,
      cartographer-klipper,
      klipper-led-effect,
      klipper-tmc-autotune,
      klippain-shaketune,
      klipperscreen,
      katapult,
      camera-streamer,
      magic-enum,
      ...
    }@inputs:
    let
      # Import the Klipper overlay with all plugin sources
      klipperOverlay = import ./overlays/klipper {
        inherit klipper-src;
        inherit cartographer-klipper;
        inherit klipper-led-effect;
        inherit klipper-tmc-autotune;
        inherit klippain-shaketune;
        inherit klipperscreen;
        inherit katapult;
      };

      # Import the camera overlay
      cameraOverlay = import ./overlays/camera {
        inherit camera-streamer;
        inherit magic-enum;
      };
    in
    {
      # NixOS configurations for Raspberry Pi 4 and 5
      nixosConfigurations = {
        "printer-pi-4" = nixos-raspberrypi.lib.nixosSystem {
          specialArgs = inputs;

          modules = [
            {
              nixpkgs.overlays = [ klipperOverlay cameraOverlay ];
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-4.base
                raspberry-pi-4.display-vc4
                raspberry-pi-4.bluetooth
              ];
            }
            ./configuration.nix
          ];
        };

        "printer-pi-5" = nixos-raspberrypi.lib.nixosSystem {
          specialArgs = inputs;

          modules = [
            {
              nixpkgs.overlays = [ klipperOverlay cameraOverlay ];
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.page-size-16k
                raspberry-pi-5.display-vc4
              ];
            }
            ./configuration.nix
          ];
        };

        # SD card image configurations (for initial installation)
        "printer-pi-4-image" = nixos-raspberrypi.lib.nixosSystem {
          specialArgs = inputs;

          modules = [
            {
              nixpkgs.overlays = [ klipperOverlay cameraOverlay ];
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-4.base
                raspberry-pi-4.display-vc4
                raspberry-pi-4.bluetooth
                sd-image
              ];
            }
            ./configuration.nix
          ];
        };

        "printer-pi-5-image" = nixos-raspberrypi.lib.nixosSystem {
          specialArgs = inputs;

          modules = [
            {
              nixpkgs.overlays = [ klipperOverlay cameraOverlay ];
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.page-size-16k
                raspberry-pi-5.display-vc4
                sd-image
              ];
            }
            ./configuration.nix
          ];
        };
      };
    };
}
