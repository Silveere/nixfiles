{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.common.me;
in
{
  options.nixfiles.common.me = {
    enable = lib.mkEnableOption "my user account";
  };

  config = lib.mkIf cfg.enable {
    users.users.nullbite = {
      uid = 1000;
      group = "nullbite";
      isNormalUser = true;
      extraGroups = [ "wheel" ] ++ lib.optional config.nixfiles.packageSets.fun.enable "input";
      packages = with pkgs; [
        keychain
      ];
      initialPassword = "changeme";
      shell = pkgs.zsh;
    };

    users.groups.nullbite.gid = 1000;

    # shell config
    programs.zsh.enable = true;
    programs.fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };
  };
}
