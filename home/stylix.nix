{ pkgs, lib, config, inputs, ... }@args:
{
  imports = [ inputs.stylix.homeManagerModules.stylix ];
  config = {
    stylix = lib.mkMerge [
      { targets.vim.enable = lib.mkDefault false; }
      # only if styix is standalone
      (lib.mkIf (!(args ? osConfig && args.osConfig ? stylix)) {
        # all of this is documented in system/stylix.nix
        autoEnable = lib.mkDefault config.stylix.enable;
        enable = lib.mkDefault false;

        image = lib.mkDefault "${pkgs.nixfiles-assets}/share/wallpapers/nixfiles-static/Djayjesse-finding_life.png";
        base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      })
    ];
  };
}
