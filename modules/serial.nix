{ config, lib, ... }:
let
  klipperSettings = config.services.klipper.settings;
in
{
  users.groups.dialout = { };
  users.groups.tty = { };
}
