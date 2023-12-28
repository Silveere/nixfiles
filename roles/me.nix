{ config, lib, pkgs, ...}:
{
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

}
