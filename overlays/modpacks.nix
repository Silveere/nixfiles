nixfiles: final: prev:
let
  inherit (final) lib;
  inherit (lib) fakeHash;
  notlite = let
    commit = "7c82e4704528fefc91fde961a78602aeb8ca3599";
    packHash = "sha256-dLLO+UBg7oA5VMn10+jmzsDndyFFw2CV0QYIFtLiOxI=";
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
