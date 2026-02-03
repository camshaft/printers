{ pkgs, config, ... }:
let
  createService =
    dev: name: port:
    let
      libDir = "/var/lib/motion/${name}";
      conf = pkgs.writeText "motion.${name}.conf" ''
        daemon off
        process_id_file ${libDir}/motion.pid
        setup_mode off
        videodevice ${toString dev}
        framerate 5
        stream_port ${toString port}
        stream_motion on
        width 320
        height 240
        ffmpeg_output_movies off
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d '${libDir}' - motion motion - -"
      ];

      systemd.services."webcam-${name}" = {
        enable = true;
        description = "WebCam '${name}'";
        after = [ "network.target" ];
        script = ''
          exec ${pkgs.motion}/bin/motion -c "${conf}"
        '';
        serviceConfig = {
          User = "motion";
          Group = "motion";
          WorkingDirectory = libDir;
          Restart = "always";
          RestartSec = "5s";
        };
      };

      services.nginx.virtualHosts."${config.networking.hostName}.lan" = {
        locations."/webcams/${name}".proxyPass = "http://127.0.0.1:${toString port}/";
      };

      services.moonraker.settings."webcam ${name}" = {
        location = name;
        stream_url = "/webcams/${name}";
      };
    };
in
(createService /dev/v4l/by-id/usb-046d_HD_Pro_Webcam_C920_A91B647F-video-index0 "printer" 9000)
// {
  users.users.motion = {
    isSystemUser = true;
    group = "motion";
    extraGroups = [
      "video"
    ];
  };
  users.groups.motion = { };

  environment.systemPackages = with pkgs; [
    motion
  ];
}
