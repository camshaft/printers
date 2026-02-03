{ pkgs, ... }:
{
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [
      "dialout" # Serial port access for MCU communication
      "gpio"
      "klipper"
      "wheel"
    ];
    hashedPassword = "$y$j9T$ksoEmaw6l0H//GJb48GPk0$qNc2QslX3tO8e4wGhB/wzrXg5pGKJVqKUGQyS/YdIu6";
  };

  users.users.root = {
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGJGdQUlU9zY/gIjXNUTLH3udNUzbFe6K7P+DHLcY40 bytheway.cameron@gmail.com"
        "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBADC3kMr2Zniu5Yo6y3V7zYd5A2ItiTgqmsLOqxeXm1uaWIo7RKPu1tyASqEt2FQlM6DFc9pLHUJ/QMLZdoFMZ2ZWgB8ctUu1I40IRSxUviectJC1NELnxXmU3lTQrWN4vDporyNBfU0g0cBxdh0h0yzOBKL5J/irvvb8Y/hO+JFlKlcqA== cameron@green-machine"
      ];
    };
  };
}
