# Camera overlay composition
#
# This module creates an overlay for camera-related packages
{ camera-streamer }:
let
  cameraStreamerOverlay = import ./camera-streamer.nix { inherit camera-streamer; };
in
# Compose all overlays into one
final: prev: cameraStreamerOverlay final prev
