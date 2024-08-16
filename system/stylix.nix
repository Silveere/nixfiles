{ pkgs, config, lib, inputs, ... }@args:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  config = {
    # stylix defaults (this is an external module so i don't mind setting sane defaults right here).
    stylix = {
      # don't mess with things by default.
      #
      # this naming is confusing as shit
      # this enables color theming of things by stylix
      autoEnable = lib.mkDefault config.stylix.enable;
      # this enables the entire module. keep this off by default.
      enable = lib.mkDefault false;

      # an image i like
      image = lib.mkDefault "${pkgs.nixfiles-assets}/share/wallpapers/nixfiles-static/Djayjesse-finding_life.png";

      # default theme
      base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      homeManagerIntegration = {
        # use system config in home-manager
        followSystem = lib.mkDefault true;

        autoImport = lib.mkDefault true;
      };
    };
  };
}
