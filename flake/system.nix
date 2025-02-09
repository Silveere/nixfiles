{ config, lib, nixfiles-lib, ... }:
let
  cfg = config.nixfiles.hosts;
  inherit (lib) types mkOption mkIf;
  inherit (nixfiles-lib.flake-legacy) mkSystem mkHome mkWSLSystem mkISOSystem;
in { }

