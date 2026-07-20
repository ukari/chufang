{
  description = "chufang";

  outputs =
    { self, ... }:
    {

      devenv = {
        bootstrap = ./devenv/bootstrap.nix;
      };

      nixos = {
        configuration = ./nixos/configuration.nix;
        nix-registry = ./nixos/nix-registry.nix;
        git = ./nixos/git.nix;
        podman = ./nixos/podman.nix;
        fhs-compat = ./nixos/fhs-compat.nix;
        xdg-compat = ./nixos/xdg-compat.nix;
        vscode-compat = ./nixos/vscode-compat.nix;
        direnv = ./nixos/direnv.nix;
        devenv = ./nixos/devenv.nix;
        constants = ./nixos/constants.nix;
        nix-overlay-store = ./nixos/nix-overlay-store.nix;
        nix-host-substituter = ./nixos/nix-host-substituter.nix;
      };

      templates = {

      };
    };
}
