{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.common.me;
in {
  options.nixfiles.common.me = {
    enable = lib.mkEnableOption "my user account";
  };

  config = lib.mkIf cfg.enable {
    users.users.nullbite = {
      uid = 1000;
      group = "nullbite";
      isNormalUser = true;
      extraGroups =
        ["wheel" "dialout"]
        ++ lib.optional config.nixfiles.packageSets.fun.enable "input"
        ++ lib.optional config.virtualisation.podman.enable "podman"
        ++ lib.optional config.hardware.openrazer.enable "openrazer";
      packages = with pkgs; [
        keychain
      ];
      # shell = pkgs.zsh;

      # this should only be configured if mutableUsers is enabled, otherwise it
      # behaves the same as `password` and takes precedence over
      # `hashedPasswordFile`, which is undesirable.
      initialPassword = lib.mkIf config.users.mutableUsers (lib.mkDefault "changeme");
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
