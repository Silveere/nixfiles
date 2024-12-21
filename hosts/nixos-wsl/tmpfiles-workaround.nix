{ config, lib, pkgs, ... }:
{
  config.systemd.tmpfiles.packages = let
    package = pkgs.runCommand "no-systemd-tmpfiles-nocow" {} ''
      mkdir -p "$out/lib/tmpfiles.d"
      cd "$out/lib/tmpfiles.d"

      ln -s /dev/null journal-nocow.conf
    '';
  in lib.mkAfter [ package ];
}
