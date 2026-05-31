{...}: let
  nixosModule = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.nixfiles.hardware.ios;
  in {
    options.nixfiles.hardware.ios.enable =
      lib.mkEnableOption "support for iOS hardware"
      // {default = true;};
    config = lib.mkIf cfg.enable {
      services.usbmuxd = {
        enable = true;
        package = pkgs.usbmuxd2;
      };
      environment.systemPackages = with pkgs; [
        libimobiledevice
        idevicerestore
        ifuse
      ];
    };
  };
in {
  config.flake.modules.nixos.nixfiles = nixosModule;
}
