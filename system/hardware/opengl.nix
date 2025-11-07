{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.hardware.opengl;
in {
  options.nixfiles.hardware.opengl.enable = lib.mkEnableOption "OpenGL configuration";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = let
      offload-enabled = config.hardware.nvidia.prime.offload.enableOffloadCmd;
      glxinfo = "${pkgs.mesa-demos}/bin/glxinfo";
      auto-offload = pkgs.writeShellScriptBin "auto-offload" (
        (
          if offload-enabled
          then ''
            if nvidia-offload ${glxinfo} > /dev/null 2>&1 ; then
              exec nvidia-offload "$@"
            fi
          ''
          else ""
        )
        + ''
          exec "$@"
        ''
      );
    in [auto-offload];
    # Enable OpenGL
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
