# Pin definition helpers for MCU configurations
#
# This module provides utilities to define pins once and automatically
# generate MCU-prefixed pins, raw pins, and board_pins aliases.
#
# Usage:
#   inherit (import ../lib/pins.nix { inherit lib; }) mkPins inv;
#
#   pinDefs = mkPins "EBB" {
#     # Simple pin (no alias)
#     board_temp = "PA0";
#     
#     # Pin with alias
#     heater = { pin = "PB4"; alias = "HOTEND"; };
#     
#     # Nested group with aliases
#     extruder = {
#       step = { pin = "PB14"; alias = "E_STEP"; };
#       dir = { pin = "PA8"; alias = "E_DIR"; };
#       enable = { pin = inv "PB6"; alias = "E_EN"; };
#     };
#     
#     # Nested group without aliases (for internal use only)
#     i2c = {
#       sda = "PA6";
#       scl = "PA7";
#     };
#   };
#
#   # Results:
#   pinDefs.pins.heater          # "EBB:PB4"
#   pinDefs.pins.extruder.step   # "EBB:PB14"
#   pinDefs.raw.heater           # "PB4"
#   pinDefs.raw.extruder.step    # "PB14"
#   pinDefs.aliases              # "HOTEND=PB4, E_STEP=PB14, E_DIR=PA8, E_EN=PB6"
#
{ lib ? import <nixpkgs/lib>, ... }:
let
  # Check if a pin string has inversion prefix
  isInverted = p: builtins.substring 0 1 p == "!";

  # Strip inversion prefix from pin
  stripInv =
    p:
    if isInverted p then builtins.substring 1 (-1) p else p;

  # Add MCU prefix to a pin, preserving inversion
  prefixPin =
    mcu: p:
    if isInverted p then "!${mcu}:${stripInv p}" else "${mcu}:${p}";

  # Check if an attrset is a pin definition (has 'pin' key)
  isPinDef = def: builtins.isAttrs def && def ? pin;

  # Process a single pin definition, returning { pin, raw, alias? }
  processPinDef =
    mcu: def:
    if builtins.isString def then
      # Simple string pin (no alias)
      {
        pin = prefixPin mcu def;
        raw = stripInv def;
        alias = null;
      }
    else if isPinDef def then
      # Pin definition with alias
      {
        pin = prefixPin mcu def.pin;
        raw = stripInv def.pin;
        alias = def.alias or null;
        desc = def.desc or null;
      }
    else
      throw "Invalid pin definition: expected string or { pin, alias?, desc? }";

  # Recursively process pin definitions
  # Returns { pins, raw, aliasList } where aliasList is a flat list of { name, value }
  processGroup =
    mcu: defs:
    let
      processEntry =
        name: def:
        if builtins.isString def || isPinDef def then
          # Leaf node (actual pin)
          let
            processed = processPinDef mcu def;
          in
          {
            pins = processed.pin;
            raw = processed.raw;
            aliasList =
              if processed.alias != null then
                [
                  {
                    inherit (processed) alias;
                    value = processed.raw;
                  }
                ]
              else
                [ ];
          }
        else if builtins.isAttrs def then
          # Nested group
          let
            nested = processGroup mcu def;
          in
          {
            pins = nested.pins;
            raw = nested.raw;
            aliasList = nested.aliasList;
          }
        else
          throw "Invalid pin definition at '${name}': expected string, pin def, or group";

      processed = builtins.mapAttrs processEntry defs;
    in
    {
      pins = builtins.mapAttrs (_: v: v.pins) processed;
      raw = builtins.mapAttrs (_: v: v.raw) processed;
      aliasList = lib.flatten (builtins.attrValues (builtins.mapAttrs (_: v: v.aliasList) processed));
    };

  # Generate aliases string from alias list
  mkAliasesString =
    aliasList:
    let
      aliasStrings = map (a: "${a.alias}=${a.value}") aliasList;
    in
    lib.concatStringsSep ", " aliasStrings;

  # Main function to create pin definitions
  # Returns { pins, raw, aliases, aliasList }
  mkPins =
    mcu: rawDefs:
    let
      result = processGroup mcu rawDefs;
    in
    {
      inherit (result) pins raw aliasList;
      aliases = mkAliasesString result.aliasList;
    };

  # Helper to create an inverted pin (for use in definitions)
  inv = p: "!${p}";

in
{
  inherit
    mkPins
    inv
    isInverted
    stripInv
    prefixPin
    ;
}
