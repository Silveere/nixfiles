{ lib, pkgs, osConfig, ... }:
let
  mkd = lib.mkDefault;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {

      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor = mkd ",preferred,auto,auto";

      # See https://wiki.hyprland.org/Configuring/Keywords/ for more

      # Execute your favorite apps at launch
      # exec-once = waybar & hyprpaper & firefox

      # Source a file (multi-file configs)
      # source = ~/.config/hypr/myColors.conf

      # Some default env vars.
      env = mkd "XCURSOR_SIZE,24";


      # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
      input = {
        kb_layout = mkd "us";
        # kb_variant = 
        # kb_model = 
        # kb_options = 
        # kb_rules = 

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
        "$mod, Q, exec, kitty"
        "$mod, C, killactive, "
        "$mod, M, exit, "
        "$mod, E, exec, dolphin"
        "$mod, V, togglefloating, "
        "$mod, R, exec, wofi --show drun"
        "$mod, P, pseudo," # dwindle"
        "$mod, J, togglesplit," # dwindle"

        # Move focus with mod + arrow keys
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

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

        # Example special workspace (scratchpad)
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mod + scroll
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];

      bindm = [
        # Move/resize windows with mod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
