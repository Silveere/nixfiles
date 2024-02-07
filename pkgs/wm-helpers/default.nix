{ pkgs, ...}:
{
  keysetting = pkgs.writeShellScript "keysetting" ''
    wpctl=${pkgs.wireplumber}/bin/wpctl
    notify_send=${pkgs.libnotify}/bin/notify-send
    brightnessctl=${pkgs.brightnessctl}/bin/brightnessctl

    notify-send () {
      $notify_send -h string:x-canonical-private-synchronous:keysetting "$@"
    }

    notifyvol () {
      notify-send "$(wpctl get-volume @DEFAULT_SINK@)"
    }

    setvol () {
      $wpctl set-volume @DEFAULT_SINK@ "$1"
      notifyvol
    }

    notifybright () {
      notify-send "Brightness: $(($($brightnessctl g)*100/$($brightnessctl m)))%"
    }

    setbright () {
      $brightnessctl s "$1"
      notifybright
    }
    case "$1" in
      volumeup) setvol 5%+ ;;
      volumedown) setvol 5%- ;;
      mute) $wpctl set-mute @DEFAULT_SINK@ toggle; notifyvol;;
      monup) setbright 5%+;;
      mondown) setbright 5%-;;
    esac
  '';
}
