{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.settings = {
    accept-flake-config = true;
  };
}
