{ config, lib, pkgs, ...}:
{
  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  users.users.nullbite = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      keychain
    ];
    initialPassword = "changeme";
    shell = pkgs.zsh;
  };

  # shell config
  programs.zsh.enable = true;
  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

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

    fd
    ripgrep
    sbctl # TODO move this elsewhere
    comma
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

}
