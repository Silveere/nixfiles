{
  config,
  lib,
  ...
}: {
  config.nixfiles.vars = {
    ### Configuration
    # My username
    username = "nullbite";
    # My current timezone for any mobile devices (i.e., my laptop)
    mobileTimeZone = "America/New_York";
  };
}
