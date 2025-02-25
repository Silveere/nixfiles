{
  lib,
  pkgs,
  config,
  osConfig ? {},
  options,
  ...
}: let
  cfg = config.nixfiles.common.nodm;
in {
  config = let
    hyprland = "${config.wayland.windowManager.hyprland.finalPackage}/bin/Hyprland";
    tty = "${pkgs.coreutils}/bin/tty";
    initCommands = ''
      if [[ "$(${tty})" == "/dev/tty1" && -z "''${WAYLAND_DISPLAY:+x}" ]] ; then
        ${hyprland}
      fi
    '';
  in
    lib.mkIf (cfg.enable && config.wayland.windowManager.hyprland.enable) {
      # auto start Hyprland on tty1
      programs.zsh.initExtra = initCommands;
      programs.bash.initExtra = initCommands;
    };

  options.nixfiles.common.nodm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to automatically start a desktop session on TTY1, behaving like a rudimentary display manager.";
      default =
        osConfig
        ? systemd
        && config.nixfiles.meta.graphical
        && (!(
          (osConfig.systemd.services.display-manager.enable or false)
          && (osConfig.systemd.services.greetd.enable or false)
        ));
      example = true;
    };
  };
}
