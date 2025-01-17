{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "cross-seed";
  version = "6.8.8";
  src = fetchFromGitHub {
    owner = "cross-seed";
    repo = "cross-seed";
    rev = "v${version}";
    hash = "sha256-7wBxjWwAV0pZjgaU0g25X+D6hRAMtzt6u3vrnlBFc38=";
  };

  npmDepsHash = "sha256-RhMb6zhKmEyuPI8qjzS7d/RQil/ZfYQl/n0dadY5KMM=";
}
