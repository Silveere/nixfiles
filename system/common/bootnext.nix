{ config, lib, pkgs, options, ... }:
let
  inherit (lib) types escapeShellArg;
  cfg = config.nixfiles.common.bootnext;
  bootNextScriptMain = pkgs.writeShellScript "bootnext-wrapped" ''
    set -Eeuxo pipefail

    PATH=${lib.escapeShellArg (with pkgs; lib.makeBinPath [ gnugrep coreutils efibootmgr ])}
    export PATH

    function do_bootnext() {
      uuid="$1"
      shift
      entryName="$1"
      shift

      efibootmgr -n "$(efibootmgr | grep -Fi "$uuid" | grep -F "$entryName" | cut -d' ' -f1 | tr -dc '[:digit:]')"
    }

    case "$1" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value:
        "  ${escapeShellArg name}) do_bootnext ${escapeShellArg value.efiPartUUID} ${escapeShellArg value.name} ;;"
      ) cfg.entries
    )}
      *) echo "Boot entry \"$1\" not configured."; exit 1;;
    esac
  '';

  bootNextScript = pkgs.writeShellScriptBin "bootnext" ''
    # this wrapper is needed because the sudoers config needs the path to the
    # actual script and self referencing is a pain. this way we can guarantee
    # that the script passed is exactly the same as the one in the sudoers
    # config. i could use realpath but this is probably safer since it is not
    # evaluated at runtime. who knows.
    if [[ "$(id -u)" -ne 0 ]]; then
      exec sudo ${escapeShellArg bootNextScriptMain} "$@"
    else
      exec ${escapeShellArg bootNextScriptMain} "$@"
    fi
  '';

in
{
  options = {
    nixfiles.common.bootnext = {
      enable = lib.mkOption {
        description = ''
          Whether to enable the bootnext wrapper command for controlling boot order
        '';
        type = types.bool;
        default = false;
        example = true;
      };
      enableDesktopEntries = lib.mkEnableOption "generation of bootnext Desktop entries";
      entries = let
        entryModule = {name, config, ... }: {
          options = let
            uuidType = with types; lib.mkOptionType {
              name = "uuid";
              description = "UUID";
              descriptionClass = "noun";
              check = let
                uuidRegex = "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$";
              in x: str.check x && (builtins.match uuidRegex x) != null;
              inherit (str) merge;
            };
          in {
            efiPartUUID = lib.mkOption {
              description = "UUID of EFI partition containing boot entry";
              type = uuidType;
              apply = lib.strings.toLower;
            };
            name = lib.mkOption {
              description = "Name of boot entry as it appears in efibootmgr";
              type = types.str;
              example = "Windows Boot Manager";
            };
            desktopEntry = {
              enable = lib.mkOption {
                description = "Whether to generate this desktop entry.";
                type = types.bool;
                default = true;
                example = false;
              };
              name = lib.mkOption {
                description = "Display name of boot entry for desktop entry.";
                type = types.str;
                default = config.name;
                example = "Windows";
              };
              icon = lib.mkOption {
                description = "Path or name of icon to use for desktop entry";
                type = with types; nullOr str;
                default = null;
              };
            };
          };
        };
      in lib.mkOption {
        description = "bootnext entry";
        type = with types; attrsOf (submodule entryModule);
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ bootNextScript ];

    security.sudo.extraRules = lib.mkAfter [
      {
        commands = [
          { command = "${bootNextScriptMain}"; options = [ "NOPASSWD" ]; }
        ];
        groups = [ "wheel" ];
      }
    ];
  };
}
