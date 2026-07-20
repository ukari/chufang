{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    direnv
    nix-direnv
  ];

  programs.direnv.enable = true;
}