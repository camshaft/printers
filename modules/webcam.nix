{ pkgs, config, ... }:
let
  # Configuration for the Logitech c920 webcam with h264 hardware encoding
  cameraDevice = "/dev/v4l/by-id/usb-046d_HD_Pro_Webcam_C920_A91B647F-video-index0";
  streamPort = 8080;
  snapshotPort = 8081;
  
  # camera-streamer configuration for high-performance h264 streaming
  cameraStreamerConfig = pkgs.writeText "camera-streamer.conf" ''
    # Use V4L2 device directly for USB webcams
    -camera-path=${cameraDevice}
    
    # Use h264 hardware encoding from the c920
    -camera-type=v4l2
    -camera-format=H264
    -camera-width=1920
    -camera-height=1080
    -camera-fps=30
    
    # HTTP server configuration
    -http-listen=127.0.0.1
    -http-port=${toString streamPort}
    
    # Snapshot configuration
    -camera-snapshot.height=720
  '';
in
{
  # camera-streamer service for webcam
  systemd.services.camera-streamer = {
    enable = true;
    description = "Camera Streamer for Logitech c920";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = "camera";
      Group = "video";
      ExecStart = "${pkgs.camera-streamer}/bin/camera-streamer @${cameraStreamerConfig}";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # Create camera user
  users.users.camera = {
    isSystemUser = true;
    group = "video";
  };

  # Nginx proxy for the camera stream
  services.nginx.virtualHosts."${config.networking.hostName}.lan" = {
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
    
    locations."/webcam/snapshot" = {
      proxyPass = "http://127.0.0.1:${toString streamPort}/snapshot";
    };
  };

  # Moonraker webcam configuration
  services.moonraker.settings.webcam.printer = {
    location = "printer";
    service = "camera-streamer";
    target_fps = 30;
    target_fps_idle = 5;
    stream_url = "/webcam/stream";
    snapshot_url = "/webcam/snapshot";
    flip_horizontal = false;
    flip_vertical = false;
    rotation = 0;
  };

  # Add camera-streamer to system packages
  environment.systemPackages = with pkgs; [
    camera-streamer
    v4l-utils
  ];
}
