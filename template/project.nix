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
  '';

  devcontainer.settings = {
    remoteUser = user;
  };
}
