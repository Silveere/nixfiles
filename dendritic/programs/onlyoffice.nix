{lib, ...}: let
  fontPackages = pkgs:
    with pkgs; [
      corefonts
      vista-fonts
      noto-fonts
      liberation_ttf
      ubuntu-sans
      atkinson-hyperlegible-next
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
      programs.onlyoffice.enable = true;
      home.packages = let
        esa = lib.escapeShellArg;
        binPath = with pkgs; "${lib.makeBinPath [coreutils findutils]}:${lib.dirOf pkgs.runtimeShell}";
        scriptSetup = ''
          set -e
          PATH=${esa binPath}
          export PATH
          XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
          export XDG_DATA_HOME
        '';
        copyfonts = pkgs.writeShellScriptBin "onlyoffice-copy-fonts" ''
          ${scriptSetup}
          mkdir -p "$XDG_DATA_HOME"/fonts
          find ${esa (fontsPkg pkgs)} -mindepth 1 -maxdepth 1 -type f -print0 \
            | xargs -0rn64 bash -c 'exec cp -rf --preserve=timestamps -- "$@" "$XDG_DATA_HOME"/fonts/' -
        '';
        # files previously copied with --preserve-timestamps will have the
        # timestamp set to epoch, otherwise this state is very rare.
        # also probably don't do this in production you moron
        rmfonts = pkgs.writeShellScriptBin "onlyoffice-remove-fonts" ''
          ${scriptSetup}
          find "$XDG_DATA_HOME"/fonts -mindepth 1 -maxdepth 1 -type f -not -newermt @1 -delete
        '';
      in [copyfonts rmfonts];
    };
  };
in {
  config = {
    flake.modules.homeManager.nixfiles = homeModule;
  };
}
