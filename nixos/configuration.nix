{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.isContainer = true;
  boot.specialFileSystems = lib.mkForce { };
  networking.resolvconf.enable = false;
  environment.etc."hosts".enable = false;
  environment.etc."hostname".enable = false;

  services.dbus.implementation = "dbus";

  nix.enable = true;
  #nix.package = pkgs.lixPackageSets.stable.lix;
  nix.settings = {
    trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];

    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.cernet.edu.cn/nix-channels/store"
      # "https://cache.iog.io"
    ];

    build-users-group = "nixbld";
    trusted-users = [ 
      "root"
      "@wheel"
    ];
    allowed-users = [
      "root"
      "@wheel"
    ];
    use-cgroups = true;
    require-drop-supplementary-groups = true;
    # auto-allocate-uids = true;
    experimental-features = [
      "nix-command"
      "flakes"
      #   "auto-allocate-uids"
      "cgroups"
    ];
  };

  system.stateVersion = "26.05";
}
