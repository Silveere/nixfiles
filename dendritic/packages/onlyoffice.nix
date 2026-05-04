{
  config,
  lib,
  self,
  ...
}: {
  config = {
    perSystem = {
      system,
      inputs,
      pkgs,
      ...
    }: {
      packages.onlyoffice =
        pkgs.callPackage
        (
          {
            lib,
            buildFHSEnvBubblewrap,
            symlinkJoin,
            runCommand,
            onlyoffice-desktopeditors,
            # font extraction
            gzip,
            mkfontscale,
            mkfontdir,
            fontalias,
            # fonts
            corefonts,
            vista-fonts,
            noto-fonts,
            liberation_ttf,
            fonts ? [
              corefonts
              vista-fonts
              noto-fonts
              liberation_ttf
            ],
            ...
          }: let
            exe = lib.getExe' onlyoffice-desktopeditors "onlyoffice-desktopeditors";
            fontsPkg = runCommand "X11-fonts" {preferLocalBuild = true;} ''
              mkdir -p "$out"
              font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
              find ${lib.escapeShellArgs fonts} -regex "$font_regexp" \
              -exec cp '{}' "$out" \;
              cd "$out"
              ${gzip}/bin/gunzip -f *.gz
              ${mkfontscale}/bin/mkfontscale
              ${mkfontdir}/bin/mkfontdir
              cat $(find ${fontalias}/ -name fonts.alias) > fonts.alias
            '';
            FHSEnv = let
            in
              buildFHSEnvBubblewrap {
                name = "${builtins.baseNameOf exe}";
                runScript = pkgs.writeShellScript "runScript" ''
                  bash
                  cp -a
                  exec ${exe};
                '';
                extraBwrapArgs = [
                  "--tmpfs /usr/share"
                  "--symlink ${fontsPkg} /usr/share/fonts"
                ];
                targetPkgs = pkgs: [
                  pkgs.onlyoffice-desktopeditors
                ];
              };
          in
            symlinkJoin {
              name = "onlyoffice-desktopeditors";
              paths = [
                FHSEnv
                onlyoffice-desktopeditors
              ];
              postBuild = ''
                rm $out/share/applications/onlyoffice-desktopeditors.desktop
                cat ${onlyoffice-desktopeditors}/share/applications/onlyoffice-desktopeditors.desktop | \
                  sed 's:^Exec=\S* \(.*\)$:Exec=${exe} \1:' > $out/share/applications/onlyoffice-desktopeditors.desktop
              '';
            }
        ) {};
    };
  };
}
