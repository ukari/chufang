{
  description = "chufang";

  outputs = { self, ... }: {
    modules = {
      infra-common = ./modules/infra-common.nix;
      infra-devcontainer = ./modules/infra-devcontainer.nix;
      infra-graphic = ./modules/infra-graphic.nix;
      lang-haskell = ./modules/lang-haskell.nix;
      lang-nix = ./modules/lang-nix.nix;
    };

    suites = {
      core = ./suites/core.nix;
    };

    templates = {
      default = {
        path = ./template;
        description = "chufang project template";
      };
    };
  };
}
