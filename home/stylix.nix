{ pkgs, lib, config, inputs, ... }@args:
{
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];
  config = {
    # only if styix is standalone
    stylix = lib.mkIf (!(args ? osConfig && args.osConfig ? stylix )) {
      autoEnable = lib.mkDefault false;
      image = lib.mkDefault "${pkgs.nixfiles-assets}/share/wallpapers/nixfiles-static/Djayjesse-finding_life.png";
      base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };
  };
}
