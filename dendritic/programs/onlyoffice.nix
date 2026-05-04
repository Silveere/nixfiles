{
  config,
  lib,
  self,
  ...
}: let
  fontPackages = pkgs:
    with pkgs; [
      corefonts
      vista-fonts
      noto-fonts
      liberation_ttf
      ubuntu-sans
    ];

  fontsPkg = pkgs:
    pkgs.runCommand "X11-fonts" {preferLocalBuild = true;} ''
      mkdir -p "$out"
      font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
      find ${lib.escapeShellArgs (fontPackages pkgs)} -regex "$font_regexp" \
      -exec cp '{}' "$out" \;
      cd "$out"
      ${pkgs.gzip}/bin/gunzip -f *.gz
    '';
  # ${pkgs.mkfontscale}/bin/mkfontscale
  # ${pkgs.mkfontdir}/bin/mkfontdir
  # cat $(find ${pkgs.fontalias}/ -name fonts.alias) > fonts.alias

  homeModule = {
    config,
    system,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.nixfiles.programs.onlyoffice;
  in {
    options.nixfiles.programs.onlyoffice.enable = lib.mkEnableOption "onlyoffice config";
    config = lib.mkIf cfg.enable {
      # xdg.dataFile.fonts = {
      #   recursive = true;
      #   source = fontsPkg pkgs;
      # };
      programs.onlyoffice.enable = true;
      home.packages = let
        find = "${pkgs.findutils}/bin/find";
        xargs = "${pkgs.findutils}/bin/xargs";
        bash = pkgs.runtimeShell;
        cp = "${pkgs.coreutils}/bin/cp";
        mkdir = "${pkgs.coreutils}/bin/mkdir";
        copyfonts = pkgs.writeShellScriptBin "onlyoffice-copy-fonts" ''
          ${mkdir} -p ~/.local/share/fonts
          ${find} ${(fontsPkg pkgs)} -mindepth 1 -maxdepth 1 -type f -print0 \
            | ${xargs} -0rn64 ${bash} -c 'exec ${cp} -rf --preserve=timestamps "$@" ~/.local/share/fonts' -
        '';
        # files previously copied with --preserve-timestamps will have the
        # timestamp set to epoch, otherwise this state is very rare.
        # also probably don't do this in production you moron
        rmfonts = pkgs.writeShellScriptBin "onlyoffice-remove-fonts" ''
          ${find} ~/.local/share/fonts -mindepth 1 -maxdepth 1 -type f -not -newermt @1 -delete
        '';
      in [copyfonts rmfonts];
    };
  };
in {
  config = {
    flake.modules.homeManager.nixfiles = homeModule;
  };
}
