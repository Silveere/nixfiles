# Configuration for root user.
# TODO this file is sorta an exception to my repo organization, it should
# probably be somewhere else.
{
  config,
  lib,
  pkgs,
  ...
} @ args: {
  imports = [
    ./.
  ];
  config = {
    nixfiles.programs.comma.enable = true;
  };
}
