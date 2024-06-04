{ lib, pkgs, config, osConfig ? {}, outputs, inputs, ... }@args:
let
  cfg = config.nixfiles.sessions.hyprland;
  mkd = lib.mkDefault;
  hyprland-pkg = config.wayland.windowManager.hyprland.finalPackage;

  # commands
  terminal = "${pkgs.kitty}/bin/kitty";
  files = "pcmanfm"; # this should be installed in path
  rofi = "${pkgs.rofi-wayland}/bin/rofi";
  notifydaemon = "${pkgs.dunst}/bin/dunst";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  polkit-agent = "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
  grimblast = "${inputs.hyprwm-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast";
  swayidle = "${pkgs.swayidle}/bin/swayidle";
  swaylock = "${config.programs.swaylock.package}/bin/swaylock";
  hyprctl = "${hyprland-pkg}/bin/hyprctl";
  pkill = "${pkgs.procps}/bin/pkill";
  swaybg = "${pkgs.swaybg}/bin/swaybg";
  hypridle = "${config.services.hypridle.package}/bin/hypridle";

  lock-cmd = "${swaylock}";

  mkKittyHdrop = name: command: let
    class = if builtins.isNull (builtins.match "[[:alnum:]_]+" name) then throw "mkKittyHdrop: window name should be an alphanumeric string" else "kitty-${name}";
    wrappedCommand = pkgs.writeShellScript "hdrop-${name}" ''
      exec bash -c ${lib.escapeShellArg command}
    '';
  in "hdrop -f -c ${class} 'kitty --class=${class} ${wrappedCommand}'";


  # lock-cmd = let
  #   cmd = pkgs.writeShellScript "lock-script" ''
  #     ${swayidle} -w timeout 10 '${hyprctl} dispatch dpms off' resume '${hyprctl} dispatch dpms on' &
  #     ${swaylock}
  #     kill %%
  #   '';
  # in "${cmd}";

  # idle-cmd = "${swayidle} -w timeout 315 '${lock-cmd}' timeout 300 '${hyprctl} dispatch dpms off' resume '${hyprctl} dispatch dpms on' before-sleep '${lock-cmd}' lock '${lock-cmd}' unlock '${pkill} -USR1 -x swaylock'";
  # idle-cmd = "${swayidle} -w timeout 300 '${hyprctl} dispatch dpms off' resume '${hyprctl} dispatch dpms on'";
  # idle-cmd = "${hypridle}";
  # idle-cmd = "${pkgs.coreutils}/bin/true";
  idle-cmd = pkgs.writeShellScript "idle-dpms-lock" ''
    ${swayidle} timeout 10 'pgrep -x swaylock > /dev/null && hyprctl dispatch dpms off' \
      resume 'hyprctl dispatch dpms on'
  '';

  hypr-dispatcher-package = pkgs.callPackage ./dispatcher { hyprland = hyprland-pkg; };
  hypr-dispatcher = "${hypr-dispatcher-package}/bin/hypr-dispatcher";

  wallpaper-package = "${pkgs.nixfiles-assets}";
  wallpaper = "nixfiles-static/Djayjesse-finding_life.png";
  wallpaper-cmd = "${swaybg} -i ${wallpaper-package}/share/wallpapers/${wallpaper}";

  # https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440#issuecomment-1900520919
  xdpg-workaround = pkgs.writeShellScript "xdg-desktop-portal-gtk-workaround"
    ''
      ${pkgs.coreutils}/bin/sleep 3
      ${pkgs.systemd}/bin/systemctl --user import-environment PATH
      ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
    '';

  # Hyprland workspace configuration
  mainWorkspaces = builtins.genList (x: x+1) (9 ++ [0]);
  workspaceName = key: let
    inherit (builtins) hasAttr;
    keyNames = {
      "0" = "10";
    };
  in
    if hasAttr key keyNames then keyNames."${key}" else key;

  inherit (outputs.packages.${pkgs.system}) wm-helpers;
  keysetting = "${wm-helpers}/bin/keysetting";
in
{
  # FIXME this is temporary just to get it working, need to make wm-common an
  # option first
  # imports = [
  #   ./wm-common.nix
  # ];

  options.nixfiles.sessions.hyprland = {
    enable = lib.mkOption {
      description = "Whether to enable hyprland.";
      type = lib.types.bool;
      default = if (builtins.hasAttr "home-manager" osConfig) then osConfig.nixfiles.sessions.hyprland.enable else false;
      example = true;
    };

    autolock = lib.mkOption {
      description = ''
        Whether to automatically lock Hyprland upon logging in. This is useful
        on a system with auto-login enabled, so that user programs can start
        automatically with the system, but there is still an added layer of
        security. This can be configured system-wide via
        nixfiles.greetd.settings.autolock.
      '';
      type = lib.types.bool;
      default = osConfig.nixfiles.programs.greetd.settings.autolock or false;
      defaultText = "osConfig.nixfiles.programs.greetd.settings.autolock or false";
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {
    nixfiles.services.hypridle.enable = true;
    nixfiles.common.wm.enable = true;
    home.packages = with pkgs; [
      kitty
      dolphin
      rofi-wayland
      wev
      dunst
      pkgs.brightnessctl
      hypr-dispatcher-package
      config.programs.swaylock.package
      pkgs.swayidle

      inputs.hyprwm-contrib.packages.${pkgs.system}.hdrop
    ];

    programs.rofi = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.rofi-wayland;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = lib.mkIf (osConfig ? programs) (lib.mkDefault osConfig.programs.hyprland.package);
      settings = {

        # enable debug logging
        debug.disable_logs = mkd false;

        # Xwayland fix
        xwayland.force_zero_scaling = mkd true;

        # See https://wiki.hyprland.org/Configuring/Monitors/
        monitor = mkd ",preferred,auto,auto";

        # See https://wiki.hyprland.org/Configuring/Keywords/ for more

        # Execute your favorite apps at launch
        # exec-once = waybar & hyprpaper & firefox

        exec-once = (lib.optional cfg.autolock lock-cmd) ++ config.nixfiles.common.wm.autostart ++
        [
          wallpaper-cmd
          notifydaemon
          polkit-agent
          idle-cmd
          xdpg-workaround
        ];

        # Source a file (multi-file configs)
        # source = ~/.config/hypr/myColors.conf

        # Some default env vars.
        # env = mkd "XCURSOR_SIZE,24";


        # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
        input = {
          kb_layout = mkd "us";
          # kb_variant = 
          # kb_model = 
          # kb_options = 
          # kb_rules = 
          kb_options = [
            "compose:ralt"
          ];

          follow_mouse = mkd true;

          touchpad.natural_scroll = mkd true;

          sensitivity = mkd 0; # -1.0 - 1.0, 0 means no modification.
        };

        general = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more

          gaps_in = mkd 5;
          gaps_out = mkd 20;
          border_size = mkd 2;
          "col.active_border" = mkd "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = mkd "rgba(595959aa)";

          layout = mkd "dwindle";

          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = mkd false;
        };

        decoration = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more
          rounding = mkd 10;

          blur = {
            enabled = mkd true;
            size = mkd 3;
            passes = mkd 1;
          };

          drop_shadow = mkd true;
          shadow_range = mkd 4;
          shadow_render_power = mkd 3;
          "col.shadow" = mkd "rgba(1a1a1aee)";
        };

        animations = {
          enabled = mkd true;

          # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

          bezier = mkd "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
          pseudotile = mkd true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = mkd true; # you probably want this
        };

        master = {
            # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
            new_is_master = mkd "true";
        };

        gestures = {
            # See https://wiki.hyprland.org/Configuring/Variables/ for more
            workspace_swipe = mkd "false";
        };

        misc = {
            # See https://wiki.hyprland.org/Configuring/Variables/ for more
            force_default_wallpaper = mkd 0; # Set to 0 to disable the anime mascot wallpapers
        };

        "$mod" = mkd "SUPER";

        # Example windowrule v1
        # windowrule = float, ^(kitty)$
        # Example windowrule v2
        # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

        # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
        bind = [
          "$mod, Q, exec, ${terminal}"
          "$mod, Return, exec, ${terminal}"
          "$mod, C, killactive, "
          "$mod, M, exit, "
          "$mod, E, exec, ${files}"
          "$mod, V, togglefloating, "
          "$mod, R, exec, ${rofi} -show drun"
          "$mod, P, pseudo," # dwindle"
          "$mod, O, togglesplit," # dwindle"

          "$mod, f, fullscreen"
          "$mod SHIFT, f, fakefullscreen"
          "$mod CTRL, f, fullscreen, 1"

          # Move focus with mod + arrow keys
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          "$mod, h, movefocus, l"
          "$mod, j, movefocus, d"
          "$mod, k, movefocus, u"
          "$mod, l, movefocus, r"

          "$mod SHIFT, h, swapwindow, l"
          "$mod SHIFT, j, swapwindow, d"
          "$mod SHIFT, k, swapwindow, u"
          "$mod SHIFT, l, swapwindow, r"

          # Switch workspaces with mod + [0-9]
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"
        #] ++ map () [] ++ TODO reconfigure these with workspace helper function
        #[
          # Move active window to a workspace with mod + SHIFT + [0-9]
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          # TODO find a different keybind for this because damn you muscle memory
          # # Example special workspace (scratchpad)
          # "$mod, S, togglespecialworkspace, magic"
          # "$mod SHIFT, S, movetoworkspace, special:magic"
          "$mod SHIFT, S, exec, ${grimblast} copy area"
          "$mod CONTROL SHIFT, S, exec, ${grimblast} copy output"
          ",Print, exec, ${grimblast} copy output"

          # lock screen
          "$mod SHIFT, x, exec, ${lock-cmd}"

          # volume mixer
          "$mod CTRL, v, exec, ${mkKittyHdrop "pulsemixer" "pulsemixer"}"

          # Scroll through existing workspaces with mod + scroll
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # show this file (help)
          ("$mod, slash, exec, ${terminal} -e ${pkgs.neovim}/bin/nvim '+set nomodifiable' '+noremap q :q<CR>'  "
          + lib.escapeShellArg (args.vars.self.outPath + "/home/sessions/hyprland/default.nix"))

          # edit this file
          ("$mod SHIFT, slash, exec, ${terminal} -e ${pkgs.neovim}/bin/nvim "
          + lib.escapeShellArg (config.nixfiles.path + "/home/sessions/hyprland/default.nix"))
        ] ++ lib.optional config.nixfiles.programs.mopidy.enable
          "$mod CTRL, n, exec, ${mkKittyHdrop "ncmpcpp" "ncmpcpp"}";

        # repeat, ignore mods
        bindei = lib.mapAttrsToList (keysym: command: ",${keysym}, exec, ${command}") config.nixfiles.common.wm.finalKeybinds
        ++ [
        ];

        bindm = [
          # Move/resize windows with mod + LMB/RMB and dragging
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
          # RMB sucks on laptop
          "$mod SHIFT, mouse:272, resizewindow"
        ];
      };
    };
  };
}
