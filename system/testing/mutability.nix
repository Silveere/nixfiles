{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.nixfiles.testing.mutability;
  file = pkgs.writeTextFile {
    name = "test";
    text = ''
      meow!
    '';
  };
in {
  options.nixfiles.testing.mutability = {
    enable = lib.mkEnableOption "mutability test";
  };

  config = lib.mkIf cfg.enable {
    environment.etc.mutability-test = {
      mode = "0644";
      source = file;
    };
  };
}
