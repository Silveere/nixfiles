{lib, ...}: let
  # each attribute here is a function which determines if a package with each
  # respective name should be allowed. this might be slightly overcomplicated
  # for my current use, but it is still relatively easy to understand and is
  # much easier to expand in the future.
  # TODO: i need to centralize my nixpkgs config, i found like 15 instances of
  # `allowUnfree` that i was gonna stick this next to
  packagePredicates = {
    ventoy = _: true;
  };

  defaultPredicate = _: false;
  allowInsecurePredicate = pkg: packagePredicates.${lib.getName pkg} or defaultPredicate;
in {
  config.nixfiles.vars = {
    inherit allowInsecurePredicate;
  };
}
