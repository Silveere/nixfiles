{ config, lib, pkgs, ... }:
let
in {
  config = {
    nixfiles.programs.syncthing.enable = true;


    systemd.timers.gallery-dl = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "13";
        RandomizedDelaySec = "4m";
      };
    };
    systemd.services.gallery-dl = {
      environment.PATH = with pkgs; makeBinpath [ bash coreutils findutils gallery-dl ];
      serviceConfig = {
        # none of your fucking business
        # TODO move this into an agenix secret probably
        ExecStart = "/srv/gallery-dl.sh";
        Type = "oneshot";
        User = "nullbite";
      };
    };

    systemd.timers.gallery-dl-dedup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:00";
        RandomizedDelaySec = "3h";
      };
    };
    systemd.services.gallery-dl-dedup = {
      environment.PATH = with pkgs; makeBinpath [ bash coreutils rmlint ];
      serviceConfig = {
        # likewise
        ExecStart = "/srv/gallery-dl-dedup.sh";
        Type = "oneshot";
        User = "nullbite";
      };
    };
  };
}
