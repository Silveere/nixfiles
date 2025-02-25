{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    enableDebugInfo = true;
    systemPackages = with pkgs; [
      gdb
    ];
  };
}
