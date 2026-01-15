{
  pkgs,
  config,
  lib,
  vars,
  ...
}: {
  config = {
    networking.hostName = "nixos-avf";

    nixfiles = {
      profile.base.enable = true;
      binfmt.enable = true;
    };

    users.users.${vars.username}.linger = true;
    # standard disclaimer don't change this for any reason whatsoever
    system.stateVersion = "26.05";
  };
}
