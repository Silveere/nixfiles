{ pkgs, config, lib, options, ... }:
let

  configForSystem = (system:
    let
      riscv = [ "riscv32-linux" "riscv64-linux" ];
      arm = [ "armv6l-linux" "armv7l-linux" "aarch64-linux" ];
      x86 = [ "i686-linux" "x86_64-linux" ];
      windows = [ "x86_64-windows" "i686-windows" ];
      systems = {
        x86_64-linux = riscv ++ arm;
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

  config = let
    enable = cfg.enable && (builtins.length emulatedSystems) > 0;
  in lib.mkMerge [
    (lib.mkIf enable {
      boot.binfmt = {inherit emulatedSystems;};
    })

    # keep Windows binfmt registration on wsl
    (lib.mkIf (cfg.enable && lib.hasAttrByPath [ "wsl" "interop" "register" ] options) {
      wsl.interop.register = lib.mkDefault true;
    })
  ];
}
