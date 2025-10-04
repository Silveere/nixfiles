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
          "attic2.protogen.io"
        ];
        api-endpoint = "https://attic2.protogen.io/";
        compression.type = "zstd";
        garbage-collection.interval = "12 hours";
      };
    };
    systemd.services.atticd.unitConfig = {
      Requires = [ "var-lib-atticd.mount" ];
      After = [ "var-lib-atticd.mount" ];
    };
  };
}
