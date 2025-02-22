{ lib
, stdenv
, cacert
, nixosTests
, rustPlatform
, fetchFromGitHub
, darwin
, nix-update-script
}:
rustPlatform.buildRustPackage rec {
  pname = "redlib";
  version = "0.35.1-unstable-2025-02-18";

  src = fetchFromGitHub {
    owner = "redlib-org";
    repo = "redlib";
    rev = "efcf2fc24c455acdf2ddc4adc8d20606883aa118";
    hash = "sha256-tcazjCxioVg13BexUnuybWKG/zaXo4xBAvb7BSvpShI=";
  };

  patches = [
    # this is so the commit hash can be embedded so redlib doesn't complain
    # about the server being outdated unless it's /actually/ outdated
    ./no-hash.patch
  ];

  cargoHash = "sha256-aQmMKXBEymvz44hwDyB7z8M4mQR0hcOHJnZ7rlJsuIw=";

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  checkFlags = [
    # All these test try to connect to Reddit.
    "--skip=test_fetching_subreddit_quarantined"
    "--skip=test_gated_and_quarantined"
    "--skip=test_fetching_nsfw_subreddit"
    "--skip=test_fetching_ws"
    "--skip=test_private_sub"
    "--skip=test_banned_sub"
    "--skip=test_gated_sub"
    "--skip=test_rate_limit_check"
    "--skip=test_default_subscriptions"

    "--skip=test_obfuscated_share_link"
    "--skip=test_share_link_strip_json"

    "--skip=test_localization_popular"
    "--skip=test_fetching_subreddit"
    "--skip=test_fetching_user"

    # These try to connect to the oauth client
    "--skip=test_oauth_client"
    "--skip=test_oauth_client_refresh"
    "--skip=test_oauth_token_exists"
    "--skip=test_oauth_headers_len"
  ];

  env = {
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    GIT_HASH=src.rev;
  };

  doCheck = false;

  passthru.tests = {
    inherit (nixosTests) redlib;
  };

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    changelog = "https://github.com/redlib-org/redlib/releases/tag/v${version}";
    description = "Private front-end for Reddit (Continued fork of Libreddit)";
    homepage = "https://github.com/redlib-org/redlib";
    license = lib.licenses.agpl3Only;
    mainProgram = "redlib";
    maintainers = with lib.maintainers; [ soispha ];
  };
}
