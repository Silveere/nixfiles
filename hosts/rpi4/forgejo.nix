{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.forgejo;
in {
  config = {
    services.forgejo = {
      enable = true;
      package = pkgs.forgejo-migrate;
      lfs.enable = true;
      settings = {
        repository = {
          ENABLE_PUSH_CREATE_USER = true;
          ENABLE_PUSH_CREATE_ORG = true;
          DEFAULT_PUSH_CREATE_PRIVATE = true;
        };

        server = {
          ROOT_URL = "https://forgejo.protogen.io/";
          LANDING_PAGE = "explore";
          OFFLINE_MODE = false;
          HTTP_PORT = 3001;
        };

        service.DISABLE_REGISTRATION = true;

        session = {
          COOKIE_NAME = "session";
          COOKIE_SECURE = false;
          PROVIDER = "file";
        };
        # TODO package themes
        ui = {
          # DEFAULT_THEME = "catppuccin-mocha-pink";
          # THEMES = let
          #   ctpAttrs = {
          #     flavor = ["latte" "frappe" "macchiato" "mocha"];
          #     accent = [
          #       "rosewater"
          #       "flamingo"
          #       "pink"
          #       "mauve"
          #       "red"
          #       "maroon"
          #       "peach"
          #       "yellow"
          #       "green"
          #       "teal"
          #       "sky"
          #       "sapphire"
          #       "blue"
          #     ];
          #   };
          #   ctpThemes =
          #     lib.mapCartesianProduct
          #     ({
          #       flavor,
          #       accent,
          #     }: "catppuccin-${flavor}-${accent}")
          #     ctpAttrs;
          # in
          #   lib.concatStringsSep "," ([
          #       "gitea"
          #       "arc-green"
          #       "auto"
          #     ]
          #     ++ ctpThemes);
        };
      };
    };
  };
}
