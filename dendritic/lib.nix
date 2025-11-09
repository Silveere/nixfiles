{lib, config, inputs, ...}: let
  inherit (lib) types mkOption warn;

  # make defining new libraries easy so i don't find ways to avoid it when it would make my life 50 times easier
  whateverType = types.submodule ({...}: {
    freeformType = types.attrsOf types.anything;
  });
in {
  options.nixfiles = {
    lib = mkOption {
      type = whateverType;
      default = {};
    };

    tmp = mkOption {
      description = ''
        Freeform option for prototyping.
      '';
      type = whateverType;
      default = {};

      apply = x: if x != { } then warn ''
        'nixfiles.tmp' was accessed during evaluation and is not empty. this
        option is for quick prototyping; don't do this in production.
      '' x else x;
    };
  };

  config = {
    _module.args = {
      nixfiles-lib = config.nixfiles.lib;
    };
  };
}
