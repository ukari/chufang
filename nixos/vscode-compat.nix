{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./fhs-compat.nix
    ./xdg-compat.nix
  ];
  users.users.vscode = {
    isNormalUser = true;
    linger = true;
    description = "vscode";
    extraGroups = [
      "wheel"
    ];
    uid = 1000;
    shell = pkgs.bashInteractive;
    packages = with pkgs; [ ];

    subUidRanges = let 
      vscodeUid = 1000;
      range1StartUid = vscodeUid + 1;
      nixbld1Uid = 30001;
      range1EndUid = nixbld1Uid - 1;
      nixbld32Uid = 30032;
      range2StartUid = nixbld32Uid + 1;
      nobodyUid = 65534;
      range2EndUid = nobodyUid - 1;
    in [
      { startUid = range1StartUid; count = (range1EndUid - range1StartUid + 1); }
      { startUid = range2StartUid; count = (range2EndUid - range2StartUid + 1); }
    ];
    subGidRanges = let 
      vscodeGid = 100;
      range1StartGid = vscodeGid + 1;
      nixbld1Gid = 30001;
      range1EndGid = nixbld1Gid - 1;
      nixbld32Gid = 30032;
      range2StartGid = nixbld32Gid + 1;
      nobodyGid = 65534;
      range2EndGid = nobodyGid - 1;
    in [
      { startGid = range1StartGid; count = (range1EndGid - range1StartGid + 1); }
      { startGid = range2StartGid; count = (range2EndGid - range2StartGid + 1); }
    ];
  };

  security.sudo = {
    wheelNeedsPassword = false;
    # extraRules = [
    #   {
    #     groups = [ "wheel" ];
    #     commands = [
    #       {
    #         command = "ALL";
    #         options = [ "NOPASSWD" ];
    #       }
    #     ];
    #   }
    # ];
  };

  environment.systemPackages = with pkgs; [
    patchelf
    gnused
    gnugrep
    gnutar
    # glibc
  ];

  environment.variables = {
    # VSCODE_SERVER_CUSTOM_GLIBC_LINKER = pkgs.stdenv.cc.bintools.dynamicLinker;
    # VSCODE_SERVER_CUSTOM_GLIBC_PATH = lib.makeLibraryPath [
    #   pkgs.glibc
    #   pkgs.stdenv.cc.cc.lib
    # ];
    # VSCODE_SERVER_PATCHELF_PATH = "${pkgs.patchelf}/bin/patchelf";
    VSCODE_SERVER_PATCHELF_PATH = "/run/current-system/sw/bin/patchelf";
    VSCODE_SERVER_CUSTOM_GLIBC_LINKER = "/run/current-system/sw/share/nix-ld/lib/ld.so";
    VSCODE_SERVER_CUSTOM_GLIBC_PATH = "/run/current-system/sw/lib:/run/current-system/sw/share/nix-ld/lib";
    PATH = "/run/wrappers/bin:/run/current-system/sw/bin:/bin:/usr/bin";
  };
}
