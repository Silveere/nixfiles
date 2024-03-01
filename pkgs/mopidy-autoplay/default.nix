{ lib, python3Packages, fetchPypi, mopidy }:

# based on mopidy/jellyfin.nix
python3Packages.buildPythonApplication rec {
  pname = "mopidy-autoplay";
  version = "0.2.3";

  src = fetchPypi {
    inherit version;
    pname = "Mopidy-Autoplay";
    sha256 = "sha256-E2Q+Cn2LWSbfoT/gFzUfChwl67Mv17uKmX2woFz/3YM=";
  };

  propagatedBuildInputs = [ mopidy ];

  # no tests implemented
  doCheck = false;
  pythonImportsCheck = [ "mopidy_autoplay" ];

   meta = with lib; {
     homepage = "https://codeberg.org/sph/mopidy-autoplay";
     description = "Mopidy extension to automatically pick up where you left off and start playing the last track from the position before Mopidy was shut down.";
     license = licenses.asl20;
   };
}
