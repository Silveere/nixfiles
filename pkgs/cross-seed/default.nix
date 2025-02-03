{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "cross-seed";
  version = "6.10.1";
  src = fetchFromGitHub {
    owner = "cross-seed";
    repo = "cross-seed";
    rev = "v${version}";
    hash = "sha256-Y8gxjJ5baj6MdxeOTP+y1zCBUus7MR1Idb1TUCIcuh4=";
  };

  npmDepsHash = "sha256-XaHGzCksa9s3abhc1l577gDEKi+O/P2iE/EN7C1qaKk=";
}
