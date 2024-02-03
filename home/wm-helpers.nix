# TODO make this into a package
{ pkgs, ...}:
{
  keysetting = pkgs.writeShellScript "keysetting" ''
    wpctl=${pkgs.wireplumber}/bin/wpctl
    notify_send=${pkgs.libnotify}/bin/notify-send

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
    case "$1" in
      volumeup) setvol 5%+ ;;
      volumedown) setvol 5%- ;;
      mute) $wpctl set-mute @DEFAULT_SINK@ toggle; notifyvol;;
    esac
  '';
}
