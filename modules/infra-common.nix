{ pkgs, ... }:
let
  # coreEnv = pkgs.buildEnv {
  #   name = "core-sandbox-env";
  #   paths = with pkgs; [
  #     git
  #     secretspec
  #     sqlite
  #   ];
  # };
in
{
  packages = with pkgs; [
  #  coreEnv
    git
    secretspec
    sqlite
  ];
}
