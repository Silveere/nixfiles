{ pkgs, config, lib, ... }:
let
  cfg = config.nixfiles.services.hypridle;
  inherit (lib.types) str int;
in
{
  options.nixfiles.services.hypridle = {
    enable = lib.mkEnableOption "the hypridle configuration";
    timeouts = let
      mkTimeout = timeout: desc: lib.mkOption {
        description = "${desc}";
        type = int;
        default = timeout;
      };
    in {
      dpms = mkTimeout (300) "DPMS timeout";
      lock = mkTimeout (360) "Lock timeout";
      locked-dpms = mkTimeout (10) "DPMS timeout while locked";
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
        listeners = let
          dpms-wrapped = pkgs.writeShellScript "dpms-wrapped" ''
            exec ${cfg.commands.dpms-off}
          '';
          lock-dpms = pkgs.writeShellScript "lock-dpms" ''
            ${pkgs.procps}/bin/pgrep swaylock > /dev/null && "${dpms-wrapped}"
          '';

        in [
          {
            timeout = cfg.timeouts.dpms;
            onTimeout = cfg.commands.dpms-off;
            onResume = cfg.commands.dpms-on;
          }
          {
            timeout = cfg.timeouts.locked-dpms;
            onTimeout = "${lock-dpms}";
            onResume = cfg.commands.dpms-on;
          }
          {
            timeout = cfg.timeouts.lock;
            onTimeout = "${config.programs.swaylock.package}/bin/swaylock";
          }
          {
            timeout = cfg.timeouts.lock + cfg.timeouts.locked-dpms;
            onTimeout = cfg.commands.dpms-off;
            onResume = cfg.commands.dpms-on;
          }
        ];

        lockCmd = "${config.programs.swaylock.package}";
        unlockCmd = "${pkgs.procps}/bin/pkill -x -USR1 swaylock";
        beforeSleepCmd = "${config.programs.swaylock.package}";
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
