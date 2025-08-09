{
  pkgs,
  config,
  lib,
  vars,
  ...
}: {
  config = {
    networking.hostName = "nixos-wsl";

    nixfiles = {
      profile.base.enable = true;
      binfmt.enable = true;
    };
    wsl.interop.register = true;

    users.users.${vars.username}.linger = true;
    systemd.services = let
      user = config.users.users.${vars.username};
      mainUid = builtins.toString user.uid;
    in {
      # "user@${mainUid}" = {
      #   wantedBy = [ "multi-user.target" ];
      #   overrideStrategy = "asDropin";
      # };
      workaround-reisolate = {
        serviceConfig = {
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
          ExecStart = [
            "${pkgs.systemd}/bin/systemctl isolate --no-block default.target"
            "${pkgs.systemd}/bin/systemctl restart --no-block user@1000"
          ];
          Type = "oneshot";
          RemainAfterExit = true;
        };
        description = "WSL startup workaround";
        wantedBy = ["default.target"];
      };
    };

    networking.networkmanager.enable = false;
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
    };

    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-sans
    ];

    fileSystems."/mnt/wsl/instances/NixOS" = {
      device = "/";
      options = ["bind"];
    };

    # standard disclaimer don't change this for any reason whatsoever
    system.stateVersion = "23.11";
  };
}
