# Printer Pi - Justfile
# Commands for building and deploying NixOS to Raspberry Pi

# Default target
default:
    @just --list

# Build the system configuration (dry-run)
check target="printer-pi-5":
    nix build .#nixosConfigurations.{{target}}.config.system.build.toplevel --dry-run

# Build the system configuration
build target="printer-pi-5":
    nix build .#nixosConfigurations.{{target}}.config.system.build.toplevel

# Build SD card image (dry-run)
check-image target="printer-pi-5":
    nix build .#images.{{target}} --dry-run

# Build SD card image
build-image target="printer-pi-5":
    nix build .#images.{{target}}

# Write SD card image to device
# Usage: just flash /dev/sdX [target]
# WARNING: This will ERASE the target device!
flash device target="printer-pi-5":
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Safety checks
    if [[ ! -b "{{device}}" ]]; then
        echo "Error: {{device}} is not a block device"
        exit 1
    fi
    
    # Check if device is mounted
    if mount | grep -q "{{device}}"; then
        echo "Error: {{device}} or one of its partitions is mounted. Unmount first:"
        mount | grep "{{device}}"
        exit 1
    fi
    
    echo "=== Building SD card image for {{target}} ==="
    nix build .#images.{{target}}

    IMAGE=$(find $(realpath result) -name '*.img' -o -name '*.img.zst' -type f | head -1)
    if [[ -z "$IMAGE" ]]; then
        echo "Error: Could not find image file in result/"
        exit 1
    fi
    
    echo ""
    echo "=== WARNING ==="
    echo "This will ERASE ALL DATA on {{device}}"
    echo "Image: $IMAGE"
    echo "Target: {{device}}"
    echo ""
    
    # Get device info for confirmation
    lsblk "{{device}}"
    echo ""
    
    read -p "Type 'yes' to continue: " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Aborted."
        exit 1
    fi
    
    echo ""
    echo "=== Writing image to {{device}} ==="
    
    if [[ "$IMAGE" == *.zst ]]; then
        sudo echo "Decompressing and writing (this may take a while)..."
        zstd -d -c "$IMAGE" | sudo dd of="{{device}}" bs=4M status=progress conv=fsync
    else
        echo "Writing image (this may take a while)..."
        sudo dd if="$IMAGE" of="{{device}}" bs=4M status=progress conv=fsync
    fi
    
    echo ""
    echo "=== Syncing ==="
    sync
    
    echo ""
    echo "=== Done! ==="
    echo "You can now remove the SD card and boot your Raspberry Pi."

# Deploy to a running system via SSH
# Usage: just deploy hostname [target]
deploy hostname target="printer-pi-5":
    nixos-rebuild switch --flake .#{{target}} --target-host root@{{hostname}}

# Update flake inputs
update:
    nix flake update

# Update a specific flake input
update-input input:
    nix flake update {{input}}

# Show flake info
info:
    nix flake show

# List available targets
targets:
    @echo "Available NixOS configurations:"
    @echo "  - printer-pi-5       (Raspberry Pi 4)"
    @echo "  - printer-pi-5       (Raspberry Pi 5)"
    @echo ""
    @echo "Available SD card images:"
    @echo "  - printer-pi-5       (Raspberry Pi 4)"
    @echo "  - printer-pi-5       (Raspberry Pi 5)"

# Format all nix files
fmt:
    nixfmt *.nix modules/*.nix modules/**/*.nix overlays/*.nix 2>/dev/null || true

# Check for errors
lint:
    nix flake check
