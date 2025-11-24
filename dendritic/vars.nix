{
  config,
  lib,
  ...
}: let
  sshKeys = {
    tz = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIISnhXFnXvFlQBDHtf1O2l6kXZPiqZaxXeyMAy6LBwGJAAAABHNzaDo= test";
  };
in {
  config.nixfiles.vars = {
    ### Configuration
    # My username
    username = "nullbite";
    # My current timezone for any mobile devices (i.e., my laptop)
    mobileTimeZone = "America/New_York";

    inherit sshKeys;
    deployKeys = with sshKeys; [
      tz
    ];
  };
}
