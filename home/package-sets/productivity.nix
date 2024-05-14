{ pkgs, lib, config, ... }:
let
  cfg = config.nixfiles.packageSets.productivity;
  inherit (lib) optionals;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; optionals config.nixfiles.meta.graphical [
      libreoffice-fresh
      obsidian
    ] ++ [
      pandoc
    ];

    xdg.desktopEntries.obsidian = lib.mkIf config.nixfiles.meta.graphical {
        categories = [ "Office" ];
        comment = "Knowledge base";
        exec = let
          extraFlags = with lib.strings;
            optionalString config.nixfiles.workarounds.nvidiaPrimary " --disable-gpu";
        in "env NIXOS_OZONE_WL=1 obsidian${extraFlags} %u";
        icon = "obsidian";
        mimeType = [ "x-scheme-handler/obsidian" ];
        name = "Obsidian";
        type = "Application";
    };
  };

  options.nixfiles.packageSets.productivity.enable = lib.mkEnableOption "the productivity package set";
}
