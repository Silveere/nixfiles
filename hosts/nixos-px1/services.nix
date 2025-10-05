{ config, lib, pkgs, ... }:
let
  inherit (config.age) secrets;
in
{
  config = {
    age.secrets = {
      atticd = {
        file = ../../secrets/atticd.age;
        group = "atticd-secret";
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

    users.groups.atticd-secret = { };

    systemd.services.atticd = {
      after = [ "postgresql.target" ];
      serviceConfig = {
        SupplementaryGroups = "atticd-secret";
      };
    };

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
