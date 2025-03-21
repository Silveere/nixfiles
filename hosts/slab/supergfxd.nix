{
  pkgs,
  lib,
  config,
  options,
  ...
} @ args: let
  gfx = {
    Integrated = {
      supergfxd = pkgs.writeText "supergfxd-integrated" ''
        {
          "mode": "Integrated",
          "vfio_enable": false,
          "vfio_save": false,
          "always_reboot": false,
          "no_logind": false,
          "logout_timeout_s": 180,
          "hotplug_type": "None"
        }
      '';
      # old def (keeping this here just in case
      # modprobe = pkgs.writeText "supergfxd-integrated-modprobe" ''
      #   # Automatically generated by supergfxd
      #   blacklist nouveau
      #   alias nouveau off
      #   blacklist nvidia_drm
      #   blacklist nvidia_uvm
      #   blacklist nvidia_modeset
      #   blacklist nvidia
      #   alias nvidia off

      #   options nvidia-drm modeset=1
      # '';
      modprobe = pkgs.writeText "supergfxd-integrated-modprobe" ''
        # Automatically generated by supergfxd
        blacklist nouveau
        blacklist nvidia_drm
        blacklist nvidia_uvm
        blacklist nvidia_modeset
        blacklist nvidia
        install nvidia_uvm /bin/false
        install nvdia_drm /bin/false
        install nvidia_modeset /bin/false
        install nvidia /bin/false
        install nouveau /bin/false

        options nvidia-drm modeset=1
      '';
    };
    Hybrid = {
      supergfxd = pkgs.writeText "supergfxd-hybrid" ''
        {
          "mode": "Hybrid",
          "vfio_enable": false,
          "vfio_save": false,
          "always_reboot": false,
          "no_logind": false,
          "logout_timeout_s": 180,
          "hotplug_type": "None"
        }
      '';
      modprobe = pkgs.writeText "supergfxd-hybrid-modprobe" ''
        # Automatically generated by supergfxd
        blacklist nouveau
        alias nouveau off
        options nvidia NVreg_DynamicPowerManagement=0x02

        options nvidia-drm modeset=1
      '';
    };
  };
  cfg = config.nixfiles.supergfxd;

  isKeyInAttrset = let
    getKeys = attrset: lib.mapAttrsToList (name: _: name) attrset;
    isInList = key: list: lib.any (x: x == key) list;
  in
    key: attrset: isInList key (getKeys attrset);

  inherit (lib) mkIf mkOption types;
in {
  options = {
    nixfiles.supergfxd.profile = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames gfx));
      default = null;
      example = "Integrated";
      description = "supergfxd profile to use";
    };
  };

  config = {
    environment.etc = mkIf (!(builtins.isNull cfg.profile)) {
      # TODO actually configure the system settings here
      "supergfxd.conf" = {
        source = gfx.${cfg.profile}.supergfxd;
        mode = "0644";
      };
      "modprobe.d/supergfxd.conf" = {
        source = gfx.${cfg.profile}.modprobe;
        mode = "0644";
      };
    };
  };
}
