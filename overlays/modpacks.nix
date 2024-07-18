nixfiles: final: prev:
let
  inherit (final) lib;
  inherit (lib) fakeHash;
  notlite = let
    commit = "1e519c6bd8267cc84ca40fcecc6d2453fac81e1b";
    packHash = "sha256-rK+yuQ/wS0QWaPglFvljnkY0FJNgXwFd+SweZZDCHWw=";
  in final.fetchPackwizModpack {
      url = "https://gitea.protogen.io/nullbite/notlite/raw/commit/${commit}/pack.toml";
      inherit packHash;
    };

  notlite-ctm-static = final.stdenvNoCC.mkDerivation {
    pname = "ctm-static";
    version = "0.0.0";
    src = final.emptyDirectory;
    nativeBuildInputs = [ final.unzip ];
    buildPhase = ''
      unzip "${notlite}/mods/create-track-map-*.jar" 'assets/littlechasiu/ctm/static/*'
      cp -r assets/littlechasiu/ctm/static/. $out/
    '';
  };
in {
  modpacks = {
    inherit notlite notlite-ctm-static;
  };
}
