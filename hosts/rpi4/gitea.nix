{ config, lib, pkgs, ... }:
let
  cfg = config.services.gitea;
in
{
  config = {
    services.gitea = {
      enable = true;
      lfs.enable = true;
      settings = {
        repository = {
          ENABLE_PUSH_CREATE_USER = true;
          ENABLE_PUSH_CREATE_ORG = true;
          DEFAULT_PUSH_CREATE_PRIVATE = true;
        };

        server = {
          ROOT_URL = "https://gitea.protogen.io/";
          LANDING_PAGE = "explore";
          OFFLINE_MODE = false;
        };

        service.DISABLE_REGISTRATION = true;

        session = {
          COOKIE_NAME = "session";
          COOKIE_SECURE = false;
          PROVIDER = "file";
        };
        # TODO package themes
        ui = {
          DEFAULT_THEME = "catppuccin-mocha-pink";
          THEMES = let
            ctpAttrs = {
              flavor = [ "latte" "frappe" "macchiato" "mocha" ];
              accent = [ "rosewater" "flamingo" "pink" "mauve"
                "red" "maroon" "peach" "yellow" "green" "teal"
                "sky" "sapphire" "blue" ];
            };
            ctpThemes = lib.mapCartesianProduct
              ( { flavor, accent }: "catppuccin-${flavor}-${accent}" )
              ctpAttrs;
          in lib.concatStringsSep "," ([
            "gitea"
            "arc-green"
            "auto"
          ] ++ ctpThemes);
        };
      };
    };
  };
}
