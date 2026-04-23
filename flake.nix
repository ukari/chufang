{
  description = "chufang";

  outputs = { self, ... }: {
    modules = {
      infra-common = ./modules/infra-common.nix;
      infra-devcontainer = ./modules/infra-devcontainer.nix;
      infra-graphic = ./modules/infra-graphic.nix;
      infra-ci-act = ./modules/infra-ci-act.nix;
      lang-haskell = ./modules/lang-haskell.nix;
      lang-haskell-registry = ./modules/lang-haskell-registry.nix;
      lang-java = ./modules/lang-java.nix;
      lang-nix = ./modules/lang-nix.nix;
      lang-python = ./modules/lang-python.nix;
    };

    suites = {
      core = ./suites/core.nix;
    };

    templates = {
      default = {
        path = ./templates/default;
        description = "chufang project template";
      };
      local-dev = {
        path = ./templates/local-dev;
        description = "chufang project template for local chufang development";
      };
    };
  };
}
