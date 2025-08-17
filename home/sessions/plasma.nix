{
  pkgs,
  config,
  lib,
  osConfig ? {},
  ...
}: let
  inherit (lib) mkOption mkEnableOption;
  cfg = config.nixfiles.sessions.plasma;
in {
  options.nixfiles.sessions.plasma = {
    enable = lib.mkOption {
      description = "Whether to enable the Plasma session home configuration.";
      type = with lib.types; bool;
      default = (osConfig.nixfiles.sessions.plasma.enable or false) && config.nixfiles.useOsConfig;
      example = true;
    };
  };
  config = lib.mkIf cfg.enable {
    # TODO make this a generic implementation
    home.packages = let
      startupScript =
        pkgs.writeShellScript "autostart-script"
        # this is really ugly. i should have done systemd units from the start, but i don't feel like rewriting this right now.
        (lib.concatStringsSep "\n"
          (builtins.map (x: "systemd-run --user -- ${lib.escapeShellArg x} &") config.nixfiles.common.wm.autostart));

      name = "home-manager-autostart";
      desktopFilePkg = pkgs.makeDesktopItem {
        inherit name;
        desktopName = "Home Manager Autostart";
        exec = startupScript;
      };
      autostartPkg = pkgs.runCommand name {} ''
        mkdir -p $out/etc/xdg/autostart
        ln -s "${desktopFilePkg}/share/applications/${name}.desktop" "$out/etc/xdg/autostart/"
      '';
    in [autostartPkg];
  };
}
