{
  config,
  lib,
  ...
}: {
  options.nixfiles.vars = lib.mkOption {
    description = "Global variables";
    type = lib.types.attrs;
    default = {};
  };
}
