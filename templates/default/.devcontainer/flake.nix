{
  description = "Description for the project";

  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    chufang-flake-dir = {
      url = "file+file:///dev/null";
      flake = false;
    };
    chufang-local-dir = {
      url = "file+file:///dev/null";
      flake = false;
    };
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; # github:cachix/devenv-nixpkgs/rolling
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    chufang = {
      url = "github:ukari/chufang";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          devenv.shells.default = {
            #name = "my-project";

            imports = [
              # inputs.chufang.suites.core
              # inputs.chufang.modules.lang-haskell
              # inputs.chufang.modules.lang-haskell-registry
              inputs.chufang.devenv.bootstrap
              ./devenv/project.nix
            ];
          };
        };

      flake =
        let
          mkNixos =
            modules:
            inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = modules;
            };
        in
        {
          nixosConfigurations.devos = mkNixos [
            inputs.chufang.nixos.configuration
            inputs.chufang.nixos.nix-registry
            inputs.chufang.nixos.git
            inputs.chufang.nixos.podman
            inputs.chufang.nixos.vscode-compat
            inputs.chufang.nixos.direnv
            inputs.chufang.nixos.devenv
            inputs.chufang.nixos.nix-access-tokens
            inputs.chufang.nixos.nix-daemon-socket
            inputs.chufang.nixos.nix-overlay-store
            inputs.chufang.nixos.nix-host-substituter
            ./nixos/configuration.nix
          ];
        };
    };
}
