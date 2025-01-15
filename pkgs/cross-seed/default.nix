{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "cross-seed";
  version = "6.8.7";
  src = fetchFromGitHub {
    owner = "cross-seed";
    repo = "cross-seed";
    rev = "v${version}";
    hash = "sha256-01F20L/D6aAzVmQxEHdlRNm/qsucr5B4LvvHukeRw/w=";
  };

  npmDepsHash = "sha256-UsWc1SShDHeBoSfF+MI0Mw639YncQe7ZFAFZlT0Gfgk=";
}
