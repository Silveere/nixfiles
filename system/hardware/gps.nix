{ config, lib, pkgs, ... }:
let
  cfg = config.nixfiles.hardware.gps;
in
{
  options = {
    nixfiles.hardware.gps = {
      enable = lib.mkEnableOption "GPS configuration";
      gpsdBridge = lib.mkOption {
        description = "Whether to enable bridging of gpsd data to Geoclue2";
        default = true;
        example = false;
        type = lib.types.bool;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.geoclue2 = {
      enable = true;
    };

    environment.etc."geoclue/conf.d/00-nmea-socket.conf".text = lib.mkIf cfg.gpsdBridge ''
      [network-nmea]
      enable=true
      nmea-socket=/run/gpsd-nmea/nmea.sock
    '';

    # this could probably be a systemd socket but i don't know how to make those
    systemd.services.gpsd-nmea-bridge = lib.mkIf cfg.gpsdBridge {
        path = with pkgs; [
          gpsd
          coreutils
          socat
        ];
        description = "gpsd to Geoclue2 GPS data bridge";
        before = [ "geoclue.service" ];
        wantedBy = [ "geoclue.service" "multi-user.target" ];
        serviceConfig = {
          RuntimeDirectory = "gpsd-nmea";
          ExecStart = pkgs.writeShellScript "gpsd-nmea-bridge" "
            exec socat -U UNIX-LISTEN:\${RUNTIME_DIRECTORY}/nmea.sock,fork,reuseaddr,mode=777 SYSTEM:'gpspipe -Br | stdbuf -oL tail -n+4'
            ";
        };
      };
    services.gpsd.enable = lib.mkIf cfg.gpsdBridge true;
  };
}
