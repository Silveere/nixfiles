{ pkgs, config, lib, inputs, ... } @ args:
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  config = {
    # stylix defaults (this is an external module so i don't mind setting sane defaults right here).
    stylix = {
      # don't mess with things by default. note: this still messes with things
      # by default; the stylix.enable option is currently being added, see
      # danth/stylix#244
      autoEnable = lib.mkDefault false;

      image = lib.mkDefault "${pkgs.nixfiles-assets}/share/wallpapers/nixfiles-static/Djayjesse-finding_life.png";
      base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      homeManagerIntegration = {
        # use system config in home-manager
        followSystem = lib.mkDefault true;

        # I will manually import within home-manager so it works standalone
        autoImport = lib.mkDefault false;
      };
    };
  };
}
