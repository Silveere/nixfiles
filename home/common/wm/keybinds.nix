{ pkgs, config, lib, outputs, ... }:
let
  df = lib.mkDefault;
  mkxf = with lib; mapAttrs' (name: value: nameValuePair ("XF86" + name) (value));

  # not rewriting this rn
  keysetting = "${outputs.packages.${pkgs.system}.wm-helpers}/bin/keysetting";
in
{
  options.nixfiles.common.wm = {
    keybinds = lib.mkOption {
      description = ''
        Attribute set containing wm-independent XF86 keysyms and associated
        commands (without the XF86 prefix)
      '';
      type = with lib.types; attrsOf str;
      default = {};
      example = {
        XF86AudioPlay = "playerctl play-pause";
      };
    };

    finalKeybinds = lib.mkOption {
      description = "Keysyms with XF86 prefix";
      type = with lib.types; attrsOf str;
      default = mkxf config.nixfiles.common.wm.keybinds;
      readOnly = true;
    };
  };
  config = {
    nixfiles.common.wm.keybinds = {
      AudioRaiseVolume = df "${keysetting} volumeup";
      AudioLowerVolume = df "${keysetting} volumedown";
      AudioMute = df "${keysetting} mute";
      AudioMicMute = df "${keysetting} micmute";

      KbdBrightnessDown = df "${keysetting} keydown";
      KbdBrightnessUp = df "${keysetting} keyup";
      MonBrightnessDown = df "${keysetting} mondown";
      MonBrightnessUp = df "${keysetting} monup";

      AudioPlay = df "playerctl play-pause";
      AudioPrev = df "playerctl previous";
      AudioNext = df "playerctl next";
    };
  };
}
