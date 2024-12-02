nixfiles: final: prev:
let
  inherit (final) lib;
  inherit (lib) fakeHash;
  notlite = let
    commit = "0e42bfbc6189db5848252d7dc7a638103d9d44ee";
    packHash = "sha256-X9a7htRhJcSRXu4uDvzSjdjCyWg+x7Dqws9pIlQtl6A=";
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
