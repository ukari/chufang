{
  description = "chufang";

  outputs =
    { self, ... }:
    {

      devenv = {
        bootstrap = ./devenv/bootstrap.nix;
        lang-python = ./devenv/lang-python.nix;
      };

      nixos = {
        configuration = ./nixos/configuration.nix;
        nix-registry = ./nixos/nix-registry.nix;
        git = ./nixos/git.nix;

        core-options = ./nixos/core-options.nix;
        mnt-constants = ./nixos/mnt-constants.nix;

        podman = ./nixos/podman.nix;
        ld-compat = ./nixos/ld-compat.nix;
        fhs-compat = ./nixos/fhs-compat.nix;
        xdg-compat = ./nixos/xdg-compat.nix;
        vscode-compat = ./nixos/vscode-compat.nix;
        direnv = ./nixos/direnv.nix;
        devenv = ./nixos/devenv.nix;
        nix-access-tokens = ./nixos/nix-access-tokens.nix;
        nix-daemon-socket = ./nixos/nix-daemon-socket.nix;
        nix-overlay-store = ./nixos/nix-overlay-store.nix;
        nix-host-substituter = ./nixos/nix-host-substituter.nix;
      };

      templates = {
        default = {
          path = ./templates/default;
          description = "chufang project template";
        };
      };
    };
}
