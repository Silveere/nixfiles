{ pkgs, config, lib, ... }:
let

  configForSystem = (system:
    let
      riscv = [ "riscv32-linux" "riscv64-linux" ];
      arm = [ "armv6l-linux" "armv7l-linux" "aarch64-linux" ];
      x86 = [ "i686-linux" "x86_64-linux" ];
      windows = [ "x86_64-windows" "i686-windows" ];
      systems = {
        x86_64-linux = riscv ++ arm ++ windows;
        aarch64-linux = riscv;
      };
    in
      if (systems ? "${system}") then systems."${system}" else []
  );
  emulatedSystems = configForSystem "${pkgs.system}";
  cfg = config.nixfiles.binfmt;
in
{
  options.nixfiles.binfmt = {
    enable = lib.mkOption {
      description = "Whether to configure default binfmt emulated systems for the current architecture";
      type = lib.types.bool;
      default = false;
      example = true;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && (builtins.length emulatedSystems) > 0) {
      boot.binfmt = {inherit emulatedSystems;}; 
    })
  ];
}
