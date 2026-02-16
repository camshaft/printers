{ pkgs, config, ... }:
let
  # Configuration for the Logitech c920 webcam with hardware H264 encoding
  cameraDevice = "/dev/v4l/by-id/usb-046d_HD_Pro_Webcam_C920_A91B647F-video-index0";
  streamPort = 8080;
  
  # camera-streamer configuration for high-performance H264 streaming
  # The c920 has hardware H264 encoding which offloads processing from the Pi CPU
  cameraStreamerConfig = pkgs.writeText "camera-streamer.conf" ''
    # Use V4L2 device directly for USB webcams
    --camera-path=${cameraDevice}
    
    # Use H264 hardware encoding from the c920
    --camera-type=v4l2
    --camera-format=H264
    --camera-width=1920
    --camera-height=1080
    --camera-fps=30
    
    # HTTP server configuration
    --http-listen=127.0.0.1
    --http-port=${toString streamPort}
    
    # Snapshot and video configuration for optimal quality
    # snapshot.height: High quality for timelapses (1080p)
    # video.height: Balanced quality for H264 video streams (720p)
    # stream.height: MJPEG stream bandwidth optimization (720p)
    # Lower resolutions for video/stream reduce bandwidth and CPU usage
    --camera-snapshot.height=1080
    --camera-video.height=720
    --camera-stream.height=720
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
  # Stream and snapshot URLs are relative to the Nginx proxy location /webcam/
  # which proxies to camera-streamer at http://127.0.0.1:8080/
  services.moonraker.settings."webcam printer" = {
    location = "printer";
    enabled = true;
    service = "webrtc-camerastreamer";
    target_fps = 30;
    target_fps_idle = 5;
    stream_url = "/webcam/stream";  # Proxied from camera-streamer's /stream endpoint
    snapshot_url = "/webcam/snapshot";  # Proxied from camera-streamer's /snapshot endpoint
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
