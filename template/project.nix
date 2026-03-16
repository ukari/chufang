{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  user = "vscode";
in
{
  packages = with pkgs; [
  
  ];

  enterShell = ''
    echo "🛡️ Devenv Sandbox Environment Activated!"
    ghc --version
  '';

  devcontainer.settings = {
    remoteUser = user;
  };
}
