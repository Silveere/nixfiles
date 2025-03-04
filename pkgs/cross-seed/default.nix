{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "cross-seed";
  version = "6.11.2";
  src = fetchFromGitHub {
    owner = "cross-seed";
    repo = "cross-seed";
    rev = "v${version}";
    hash = "sha256-m/TlEAW9BFEXOvBixOj09ylgstgHKL48e9zC50fzD5g=";
  };

  npmDepsHash = "sha256-c8wTvEA7QQb17gBHdBKMUatn8I/wKOhXP1W5ftH3pJc=";
}
