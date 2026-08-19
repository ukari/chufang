{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ld-compat.nix
  ];
  environment.systemPackages = with pkgs; [
    coreutils
  ];

  # programs.nix-ld.libraries = with pkgs; [
  #   stdenv.cc.cc.lib
  # ];

}