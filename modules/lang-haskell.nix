{
  pkgs,
  lib,
  config,
  ...
}:
let
  ctx = pkgs.callPackage ../lib/mk-context.nix { inherit config; };
  user = ctx.user;
  stackRoot = "${ctx.homeDir}/.stack";
in
{
  languages.haskell = with pkgs; {
    enable = true;
    package = lib.mkDefault haskell.compiler.ghc910;
    lsp.enable = lib.mkDefault true;
  };

  packages = with pkgs; [
    haskellPackages.haskell-debug-adapter
  ];

  devcontainer.settings = {
    mounts = [
      {
        source = ctx.scoped "stack-cache";
        target = "${stackRoot}";
        type = "volume";
      }
    ];

    postCreateCommand = ''
      if [ "$(stat -c '%U:%G' ${stackRoot})" != "${user}:${user}" ]; then
        sudo chown -R ${user}:${user} ${stackRoot}
      fi
    '';

    customizations = {
      vscode = {
        extensions = [
          "haskell.haskell"
          # "well-typed.haskell-debugger-extension"
          "visortelle.haskell-spotlight"
        ];

        settings = {
          "haskell.manageHLS" = "PATH";
          "haskell.upgradeGHCup" = false;
          "haskell.ghcupExecutablePath" = "";
          "haskell.serverExecutablePath" = "haskell-language-server-wrapper";
        };

      };
    };
  };
}
