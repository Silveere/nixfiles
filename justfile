alias upkgs := update-pkgs
alias uf    := update-flake
alias ue    := update-essential
alias u     := update

_default:
    @just --list

# Start a Nix devShell
shell:
    nix develop

# Update everything
update: update-pkgs update-flake

# Update nvfetcher sources
update-pkgs:
    nvfetcher

# Update flake inputs
update-flake:
    nix flake update

# Update "essential" inputs
update-essential:
    nix flake lock --update-input zen-browser

fmt:
    nix develop . --command formatter

# Preload then deploy
pdeploy: preload deploy

# Deploy to nodes
deploy:
    deploy -s --remote-build

# Preload update to deploy targets
preload:
    # this is horrible
    # waiting for https://github.com/serokell/deploy-rs/issues/46
    nix eval .#deploy.nodes --apply builtins.attrNames --json | jq '.[]' --raw-output0 | xargs -0n1 -P6 bash -c 'exec deploy -s --remote-build --dry-activate ".#$1"'

# View GitHub Actions build logs
log:
    env PAGER='nvim -R +set\ ic\ scs\ nowrap' gh run view --log-failed

# Attempt to build the current head via GitHub actions
try-update:
    git push origin HEAD:force-build
    sleep 20
    git push origin :force-build
