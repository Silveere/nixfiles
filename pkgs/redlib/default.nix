{ lib
, stdenv
, cacert
, nixosTests
, rustPlatform
, fetchFromGitHub
, darwin
}:
rustPlatform.buildRustPackage rec {
  pname = "redlib";
  version = "0.35.1";

  src = fetchFromGitHub {
    owner = "redlib-org";
    repo = "redlib";
    # rev = "refs/tags/v${version}";
    rev = "793047f63f0f603e342c919bbfc469c7569276fa";
    hash = "sha256-A6t/AdKP3fCEyIo8fTIirZAlZPfyS8ba3Pejp8J6AUQ=";
  };

  patches = [
  ];

  cargoHash = "sha256-rJXKH9z8DC+7qqawbnSkYoQby6hBLLM6in239Wc8rvk=";

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  checkFlags = [
    # All these test try to connect to Reddit.
    "--skip=test_fetching_subreddit_quarantined"
    "--skip=test_gated_and_quarantined"
    "--skip=test_fetching_nsfw_subreddit"
    "--skip=test_fetching_ws"

    "--skip=test_obfuscated_share_link"
    "--skip=test_share_link_strip_json"

    "--skip=test_localization_popular"
    "--skip=test_fetching_subreddit"
    "--skip=test_fetching_user"

    # These try to connect to the oauth client
    "--skip=test_oauth_client"
    "--skip=test_oauth_client_refresh"
    "--skip=test_oauth_token_exists"
  ];

  env = {
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  passthru.tests = {
    inherit (nixosTests) redlib;
  };

  meta = {
    changelog = "https://github.com/redlib-org/redlib/releases/tag/v${version}";
    description = "Private front-end for Reddit (Continued fork of Libreddit)";
    homepage = "https://github.com/redlib-org/redlib";
    license = lib.licenses.agpl3Only;
    mainProgram = "redlib";
    maintainers = with lib.maintainers; [ soispha ];
  };
}
