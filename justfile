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

# View GitHub Actions build logs
log:
    env PAGER='nvim -R +set\ ic\ scs\ nowrap' gh run view --log-failed

# Attempt to build the current head via GitHub actions
try-update:
    git push origin HEAD:force-build
    sleep 20
    git push origin :force-build
