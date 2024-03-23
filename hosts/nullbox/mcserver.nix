{ pkgs, lib, config, ... }:
{
  config = {
    fileSystems."/srv/mcserver".options = [ "compress=zstd" "nofail" ];
  };
}
