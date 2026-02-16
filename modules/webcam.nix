{ pkgs, config, ... }:
let
  # Configuration for the Logitech c920 webcam
  cameraDevice = "/dev/v4l/by-id/usb-046d_HD_Pro_Webcam_C920_A91B647F-video-index0";
  streamPort = 8080;
in
{
  # ustreamer service for webcam
  systemd.services.ustreamer = {
    enable = true;
    description = "uStreamer for Logitech c920";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = "root";
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.ustreamer}/bin/ustreamer"
        "--device=${cameraDevice}"
        "--host=127.0.0.1"
        "--port=${toString streamPort}"
        # Resolution and framerate
        "--resolution=1280x720"
        "--desired-fps=30"
        # Use MJPEG from camera directly (no encoding needed)
        "--format=MJPEG"
        # Performance tuning
        "--workers=2"
        "--drop-same-frames=30"
      ];
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # Nginx proxy for the camera stream
  services.nginx.virtualHosts."${config.networking.hostName}.lan" = {
    # ustreamer endpoints:
    #   / - web interface
    #   /stream - MJPEG stream
    #   /snapshot - JPEG snapshot
    locations."/webcam/" = {
      proxyPass = "http://127.0.0.1:${toString streamPort}/";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  # Moonraker webcam configuration
  # ustreamer endpoints: /stream (MJPEG), /snapshot (JPEG)
  services.moonraker.settings."webcam printer" = {
    location = "printer";
    enabled = true;
    service = "mjpegstreamer-adaptive";
    target_fps = 30;
    target_fps_idle = 5;
    stream_url = "/webcam/stream";
    snapshot_url = "/webcam/snapshot";
    flip_horizontal = false;
    flip_vertical = false;
    rotation = 0;
  };

  # Add tools to system packages
  environment.systemPackages = with pkgs; [
    ustreamer
    v4l-utils
  ];
}
