{ config, lib, pkgs, ...}:
{
  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = lib.mkDefault true;  # Easiest to use and most distros use this by default.

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    git
    stow
    zsh
    ntfs3g
    openssh

    fd
    ripgrep
    sbctl # TODO move this elsewhere
    comma
    nil
  ];

  programs.ssh.enableAskPassword = false;

  programs.gnupg.agent = {
    enable = lib.mkDefault true;
    enableSSHSupport = lib.mkDefault true;
  };

}
