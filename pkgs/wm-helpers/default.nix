{
  pkgs,
  lib,
  cap-volume ? true,
  unmute ? true,
  ...
}: let
  keysetting =
    pkgs.writeShellScriptBin "keysetting"
    ''
      wpctl=${pkgs.wireplumber}/bin/wpctl
      notify_send=${pkgs.libnotify}/bin/notify-send
      brightnessctl=${pkgs.brightnessctl}/bin/brightnessctl
      cut=${pkgs.coreutils}/bin/cut
      grep=${pkgs.gnugrep}/bin/grep
      tr=${pkgs.coreutils}/bin/tr
      bc=${pkgs.bc}/bin/bc

      cap_volume=${pkgs.coreutils}/bin/${lib.boolToString cap-volume}
      unmute=${pkgs.coreutils}/bin/${lib.boolToString unmute}

      notify-send () {
        $notify_send -h string:x-canonical-private-synchronous:keysetting "$@"
      }

      getvol () {
        echo "$(wpctl get-volume @DEFAULT_SINK@ | $tr -dc '[:digit:].')*100/1" | $bc
      }

      notifyvol () {
        message="Volume: $(getvol)%"
        if $wpctl get-volume @DEFAULT_SINK@ | $grep MUTED > /dev/null ; then
          message="$message [MUTED]"
        fi
        notify-send "$message"
      }

      setvol () {
        $wpctl set-volume @DEFAULT_SINK@ "$1"
        notifyvol
      }

      volup () {
        if $unmute ; then
          $wpctl set-mute @DEFAULT_SINK@ 0
        fi

        if $cap_volume && [[ $(( $(getvol) + 5 )) -gt 100 ]] ; then
          setvol 1
          return
        fi

        setvol 5%+
        # notifyvol
      }

      voldown () {
        if $unmute ; then
          $wpctl set-mute @DEFAULT_SINK@ 0
        fi
        setvol 5%-
        # notifyvol
      }

      notifybright () {
        notify-send "Brightness: $(($($brightnessctl g)*100/$($brightnessctl m)))%"
      }

      setbright () {
        $brightnessctl s "$1"
        notifybright
      }
      case "$1" in
        volumeup) volup ;;
        volumedown) voldown ;;
        mute) $wpctl set-mute @DEFAULT_SINK@ toggle; notifyvol;;
        monup) setbright 5%+;;
        mondown) setbright 5%-;;
      esac
    '';
in
  pkgs.symlinkJoin {
    name = "wm-helpers";
    paths = [
      keysetting
    ];
  }
