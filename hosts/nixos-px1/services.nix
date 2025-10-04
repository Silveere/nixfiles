{ config, lib, pkgs, ... }:
let
  inherit (config.age) secrets;
in
{
  config = {
    age.secrets = {
      atticd = {
        file = ../../secrets/atticd.age;
        group = "atticd";
      };
    };

    services.atticd = {
      enable = true;
      environmentFile = secrets.atticd.path;
      settings = {
        allowed-hosts = [
          "attic.protogen.io"
          "attic2.protogen.io" # temporary for migration/testing
        ];
      };
    };
    systemd.services.atticd.unitConfig = {
      Requires = [ "var-lib-atticd.mount" ];
      After = [ "var-lib-atticd.mount" ];
    };
  };
}
