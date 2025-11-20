{...}: {
  config.perSystem = {...}: {
    pre-commit.settings = {
      hooks = {
        treefmt = {
          enable = true;
        };
      };
    };
  };
}
