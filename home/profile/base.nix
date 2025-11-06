{
  lib,
  pkgs,
  config,
  osConfig ? {},
  ...
}: let
  cfg = config.nixfiles.profile.base;
in {
  # imports = [
  #   ./comma.nix
  # ];
  # home.username = "nullbite";
  # home.homeDirectory = "/home/nullbite";

  options.nixfiles.profile.base = {
    enable = lib.mkEnableOption "base profile";
  };

  options.programs.git.maintenance.requiredKeys = lib.mkOption {
    description = ''
      List of SSH keys which should be loaded into an agent before attempting
      to prefetch SSH repositories.
    '';
    type = with lib.types; listOf str;
    default = [ ];
  };

  config = lib.mkIf cfg.enable {
    nixfiles.programs.comma.enable = true;
    nixfiles.programs.neovim.enable = lib.mkDefault true;
    nixfiles.common.nix.enable = true;
    nixfiles.common.shell.enable = true;

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf config.programs.neovim.enable {
        MANPAGER = "nvim +Man!";
      })

      # configure terminfo since we're probably standalone
      (lib.mkIf (!(osConfig ? environment)) {
        TERMINFO_DIRS = let
          terminfo-dirs = [
            "${config.home.profileDirectory}/share/terminfo"
            "/usr/share/terminfo"
          ];
        in
          builtins.concatStringsSep ":" terminfo-dirs;
      })
    ];

    programs.git = {
      enable = lib.mkDefault true;
      maintenance.enable = lib.mkDefault true;
      # default value is stateVersion dependent, doesn't evaluate after 25.05
      # even if signing isn't configured for some reason
      signing.format = lib.mkDefault "openpgp";
    };

    # git maintenance: don't spam endpoints, ignore failure
    systemd.user.services."git-maintenance@".Service = lib.mkIf config.programs.git.maintenance.enable {
      SuccessExitStatus = [
        "1" # i do not care if it fails
      ];
      Environment = let
        ssh_wrapper = pkgs.writeShellScript "ssh-wrapper" ''
          # echo "ssh wrapper called with:" "$@" >&2
          set -Eeuo pipefail

          ${builtins.concatStringsSep "\n" (builtins.map
            (key: "${pkgs.openssh}/bin/ssh-add -l | grep -F ${lib.escapeShellArg key} >&2 || exit 1")
            config.programs.git.maintenance.requiredKeys)}

          exec ${pkgs.openssh}/bin/ssh -S none -o BatchMode=yes -o ConnectTimeout=5 -o PreferredAuthentications=publickey "$@"
        '';
      in [
          "GIT_SSH=${ssh_wrapper}"
        ];
    };

    # this allows `git config --global` commands to work by ensuring the
    # presense of ~/.gitconfig. git will read from both files, and `git config`
    # will not write to ~/.gitconfig when the managed config exists unless
    # ~/.gitconfig also exists
    home.activation.git-create-gitconfig =
      lib.mkIf config.programs.git.enable
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        _nixfiles_git_create_gitconfig () {
          if ! [[ -a "$HOME/.gitconfig" ]] ; then
            touch "$HOME/.gitconfig"
          fi
        }
        run _nixfiles_git_create_gitconfig
      '');

    programs.btop.enable = lib.mkDefault true;

    programs.ranger = let
      defaultTerminal = "kitty";
      # defaultTerminal =
      #   if config.programs.kitty.enable then "kitty"
      #     else null;
    in {
      enable = lib.mkDefault true;
      settings = lib.mkMerge [
        {
          use_preview_script = lib.mkDefault true;
          preview_files = lib.mkDefault true;
        }
        (lib.mkIf (!(isNull defaultTerminal)) {
          preview_images = lib.mkDefault true;
          preview_images_method = lib.mkDefault defaultTerminal;
        })
      ];
    };

    programs.keychain = {
      enable = lib.mkDefault true;
      enableBashIntegration = lib.mkDefault true;
      enableZshIntegration = lib.mkDefault true;
      keys = lib.mkDefault [
        "id_rsa"
        "id_ed25519"
      ];
      extraFlags = [
        "--quiet"
        "--quick" # faster algorithm that avoids lockfiles
        "--noask" # do not block the terminal or i will become very angry
        "--ignore-missing"
        "--ssh-allow-forwarded"
        "--systemd" # populate systemd vars
        # keychain --quiet --quick --noask --ignore-missing --ssh-allow-forwarded --debug id_rsa id_ed25519
      ];
    };

    # this fixes a lot of theme weirdness
    # this actually breaks home-manager's icon/theme management
    # home.file.".icons".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/icons";
    # home.file.".themes".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/themes";

    # some packages defined here may be redundant with packages on a non-NixOS
    # home-manager setup, but it's better to have a consistent environment at
    # the cost of slightly more space
    home.packages = with pkgs; let
      neofetch-hyfetch-shim = writeShellScriptBin "neofetch" ''
        exec "${pkgs.hyfetch}/bin/neowofetch" "$@"
      '';

      flocate = let
        # fzf and nix-locate are the only things that would reasonably not
        # exist on a local system. nix-locate is fine to be left as-is because
        # i use a prebuilt db so i already know it is installed
        #
        fzf = lib.escapeShellArg (lib.getExe' pkgs.fzf "fzf");
      in
        writeShellScriptBin "flocate" ''
          nix-locate "$@" | stdbuf -oL grep -v '^(' \
            | ${fzf} \
            | cut -d' ' -f1 \
            | xargs bash -c 'exec nix build --no-link --print-out-paths nixpkgs${lib.optionalString (config.nix.registry ? nixpkgs-local) "-local"}#"$1"' -
        '';
    in
      [
        # nix stuff
        nvd
        nix-tree
        nh
        nix-output-monitor
        attic-client
        nix-fast-build

        git
        git-lfs
        stow
        curl
        httpie
        gh

        # shell
        ripgrep
        fd
        bat
        moreutils
        grc
        fzf
        pv
        lsof
        xxd
        shellcheck
        ## text processing (json etc)
        jq
        yq # jq for yaml/toml/xml
        jo # easy json shorthand
        jc # convert command outputs to json
        jless # less for json
        gron # forty seven (greppable json)
        fq # jq like binary parser ?

        # for icat on all systems
        kitty.kitten

        # pretty
        hyfetch
        neofetch-hyfetch-shim
        fastfetch

        # files
        restic
        rclone
        rmlint
        ncdu

        # compression
        atool-wrapped
        lzip
        plzip
        lzop
        xz
        zip
        unzip
        arj
        rpm
        cpio
        p7zip

        # other utilities
        tmux
        tmuxp
        openssh
        autossh
        mosh
        btop
        htop
        zoxide
        asciinema
        mtr
        qrencode
        zbar

        screen
        minicom
        picocom

        # man pages
        man-pages
        linux-manual
        linux-doc

        # custom
        flocate
      ]
      ++ builtins.map (x: lib.hiPrio x) [
        # terminfo (just the ones i'm likely to use)
        kitty.terminfo
        alacritty.terminfo
        termite.terminfo
        tmux.terminfo
      ];
  };
}
