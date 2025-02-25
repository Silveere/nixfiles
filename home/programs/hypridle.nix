{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.nixfiles.services.hypridle;
  inherit (lib.types) str int;
in {
  options.nixfiles.services.hypridle = {
    enable = lib.mkEnableOption "the hypridle configuration";
    timeouts = let
      mkTimeout = timeout: desc:
        lib.mkOption {
          description = "${desc}";
          type = int;
          default = timeout;
        };
    in {
      dpms = mkTimeout 300 "DPMS timeout";
      lock = mkTimeout 360 "Lock timeout";
      locked-dpms = mkTimeout 10 "DPMS timeout while locked";
    };
    commands = {
      dpms-off = lib.mkOption {
        description = "DPMS off command";
        default = "hyprctl dispatch dpms off";
        type = str;
      };
      dpms-on = lib.mkOption {
        description = "DPMS on command";
        default = "hyprctl dispatch dpms on";
        type = str;
      };

      # lock = lib.mkOption {
      #   description = "Lock command";
      #   default = "${pkgs.swaylock}/bin/swaylock";
      #   type = str;
      # };
      # unlock = lib.mkOption {
      #   description = "Unlock command";
      #   default = "${pkgs.procps}/bin/pkill -USR1 swaylock";
      #   type = str;
      # };
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.hypridle = {
        enable = true;
        settings = let
          lock = pkgs.writeShellScript "lock-once" ''
            ${pkgs.procps}/bin/pgrep -x swaylock > /dev/null || "${config.programs.swaylock.package}/bin/swaylock"
          '';
        in {
          listener = let
            dpms-wrapped = pkgs.writeShellScript "dpms-wrapped" ''
              exec ${cfg.commands.dpms-off}
            '';
            lock-dpms = pkgs.writeShellScript "lock-dpms" ''
              ${pkgs.procps}/bin/pgrep -x swaylock > /dev/null && "${dpms-wrapped}"
            '';
          in [
            {
              timeout = cfg.timeouts.dpms;
              on-timeout = cfg.commands.dpms-off;
              on-resume = cfg.commands.dpms-on;
            }
            # {
            #   timeout = cfg.timeouts.locked-dpms;
            #   on-timeout = "${lock-dpms}";
            #   on-resume = cfg.commands.dpms-on;
            # }
            {
              timeout = cfg.timeouts.lock;
              on-timeout = "${lock}";
            }
            {
              timeout = cfg.timeouts.lock + cfg.timeouts.locked-dpms;
              on-timeout = cfg.commands.dpms-off;
              on-resume = cfg.commands.dpms-on;
            }
          ];

          general = {
            lock_cmd = "${lock}";
            unlock_cmd = "${pkgs.procps}/bin/pkill -x -USR1 swaylock";
            before_sleep_cmd = "${config.programs.swaylock.package}";
            ignore_dbus_inhibit = false;
            # after_sleep_cmd = "echo 'Awake...'";
          };
        };
      };
    })
    # why isn't this handled automatically??
    (lib.mkIf config.services.hypridle.enable {
      home.packages = with pkgs; [
        hypridle
      ];
    })
  ];
}
