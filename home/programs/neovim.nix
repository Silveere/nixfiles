{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfiles.programs.neovim;
in {
  options.nixfiles.programs.neovim.enable = lib.mkEnableOption "the Neovim configuration";
  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = lib.mkDefault true;
      withPython3 = lib.mkDefault true;
      defaultEditor = lib.mkDefault true;
      extraPackages = with pkgs; [
        lua-language-server
        rust-analyzer
        vscode-langservers-extracted
        pyright
        gcc
      ];
    };
  };
}
