nixfiles: final: prev:
let
  inherit (final) lib;
  inherit (lib) fakeHash;
  notlite = let
    commit = "7697c3a";
    packHash = "sha256-/IA/NP1w9RcWg+71lxUN+Q3hz12GhN/e4lkSnaYyAb4=";
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
