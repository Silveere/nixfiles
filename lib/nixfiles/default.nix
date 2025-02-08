{...} @ attrs: let
  # compatibility with old loading system (this looks awful fix this when i
  # fully migrate to flake-parts). this constructs an attrset that resembles
  # what the old args used to look like in attrs', so i don't have to rewrite
  # all of the glue. it creates a fake pkgs value containing only `lib`.
  #
  # actually no idk if i can fix this because it needs to be accessible from
  # everything (flake, nixos/home-manager modules, maybe derivations). this
  # might be the best way to do this so i can pass in either pkgs or lib based
  # on the current context, and just return relevant libraries based on that
  # input.
  #
  # create empty `pkgs` with lib only `lib` attr as fallback
  pkgs = attrs.pkgs or {inherit (attrs) lib;};
  # inherit lib from whatever `pkgs` happens to be
  inherit (pkgs) lib;

  # compat
  attrs' = attrs // {inherit pkgs;};
in
  {
    types = (import ./types.nix) attrs';
  }
  # only if an actual `pkgs` was passed
  // lib.optionalAttrs (attrs ? pkgs) {
    minecraft = (import ./minecraft.nix) attrs';
  }
