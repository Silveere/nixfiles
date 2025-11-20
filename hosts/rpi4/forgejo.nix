{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.forgejo;
  themes = pkgs.symlinkJoin {
    name = "forgejo-themes";
    paths = [
      pkgs.nvfetcherSources.catppuccin-gitea.src
    ];
  };
in {
  config = {
    systemd.tmpfiles.rules = lib.mkIf cfg.enable [
      "L+ '${cfg.customDir}/public/assets/css' - - - - ${themes}"
    ];

    services.forgejo = {
      enable = true;
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
          HTTP_PORT = 3003;
        };

        service.DISABLE_REGISTRATION = true;

        session = {
          COOKIE_NAME = "session";
          COOKIE_SECURE = false;
          PROVIDER = "file";
        };
        # TODO package themes
        ui = {
          DEFAULT_THEME = "catppuccin-peach-auto";
          THEMES = let
            ctpAttrs = {
              flavor = ["latte" "frappe" "macchiato" "mocha"];
              accent = [
                "rosewater"
                "flamingo"
                "pink"
                "mauve"
                "red"
                "maroon"
                "peach"
                "yellow"
                "green"
                "teal"
                "sky"
                "sapphire"
                "blue"
              ];
            };
            ctpThemes =
              (lib.mapCartesianProduct
              ({
                flavor,
                accent,
              }: "catppuccin-${flavor}-${accent}")
              ctpAttrs)
              ++ builtins.map (accent: "catppuccin-${accent}-auto") ctpAttrs.accent;
          in
            lib.concatStringsSep "," ([
              "forgejo-auto"
              "forgejo-light"
              "forgejo-dark"
              "gitea-auto"
              "gitea-light"
              "gitea-dark"
              "forgejo-auto-deuteranopia-protanopia"
              "forgejo-light-deuteranopia-protanopia"
              "forgejo-dark-deuteranopia-protanopia"
              "forgejo-auto-tritanopia"
              "forgejo-light-tritanopia"
              "forgejo-dark-tritanopia"
            ] ++ ctpThemes);
        };
      };
    };
  };
}
