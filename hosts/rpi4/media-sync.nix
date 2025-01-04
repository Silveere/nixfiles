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
      script = ''
        PATH=${with pkgs; lib.escapeShellArg (lib.makeBinPath [ bash coreutils findutils gallery-dl ])}
        export PATH

        # none of your fucking business
        # TODO move this into an agenix secret probably
        exec /srv/gallery-dl.sh
      '';

      serviceConfig = {
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
      script = ''
        PATH=${with pkgs; lib.escapeShellArg (lib.makeBinPath [ coreutils rmlint ])}
        export PATH

        exec /srv/gallery-dl-dedup.sh
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "nullbite";
      };
    };
  };
}
