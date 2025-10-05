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
        database.url = "postgres://atticd?host=/run/postgresql";
        allowed-hosts = [
          "attic2.protogen.io"
        ];
        api-endpoint = "https://attic2.protogen.io/";
        compression.type = "zstd";
        garbage-collection.interval = "12 hours";
      };
    };

    systemd.services.attic.after = [
      "postgresql.target"
    ];

    services.postgresql = {
      enable = lib.mkDefault true;

      ensureDatabases = [ "atticd" ];
      ensureUsers = [
        {
          name = config.services.atticd.user;
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
