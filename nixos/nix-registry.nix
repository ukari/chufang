{ lib, inputs, ... }:
{
  nixpkgs.flake.setFlakeRegistry = false;
  nixpkgs.flake.setNixPath = false;

  nix.registry.nixpkgs.flake = lib.mkDefault inputs.nixpkgs;
}
