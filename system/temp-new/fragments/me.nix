{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.common.me;
in
{
  options.nixfiles.common.me = lib.mkEnableOption "my user account";
  config = lib.mkIf cfg.enable {
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
  };
}
