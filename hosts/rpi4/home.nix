{config, ...}: {
  config = {
    nixfiles = {
      profile.base.enable = true;
      packageSets.multimedia.enable = true;
    };
    programs.keychain.enable = false;
  };
}
