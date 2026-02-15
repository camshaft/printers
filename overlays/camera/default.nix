# Camera overlay composition
#
# This module creates an overlay for camera-related packages
{ }:
let
  cameraStreamerOverlay = import ./camera-streamer.nix;
in
# Compose all overlays into one
final: prev: cameraStreamerOverlay final prev
