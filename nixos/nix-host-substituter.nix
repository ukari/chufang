{
  config,
  lib,
  pkgs,
  ...
}:

let
  constants = import ./constants.nix;
  hostNixRoot = constants.hostNixRoot;
  hostNixMnt = constants.hostNixMnt;
  hostNixStore = "${hostNixMnt}/store";
  hostNixRegistryMnt = constants.hostNixRegistryMnt;

  runtimeDirName = "chufang/nix-host-substituter";
  runtimeDir = "/run/${runtimeDirName}";
  dynamicNixRegistryJsonPath = "${runtimeDir}/dynamic-nix-registry.json";

  nixHostSubstituterConfPath = "${runtimeDir}/host-nix.conf";
  nixHostSubstituterConfFile = ''
    extra-substituters = local?root=${hostNixRoot}&read-only=true&trusted=true&priority=1
    extra-trusted-substituters = local?root=${hostNixRoot}&read-only=true&trusted=true
    flake-registry = ${dynamicNixRegistryJsonPath}
  '';
in
{
  systemd.services.nix-host-substituter = {
    wantedBy = [ ];
    before = [ ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = runtimeDirName;
    };

    unitConfig = {
      ConditionPathIsMountPoint = [
        hostNixMnt
        hostNixRegistryMnt
      ];
    };

    script = ''
      sed "s|\"/nix/store|\"${hostNixStore}|g" ${hostNixRegistryMnt} > ${dynamicNixRegistryJsonPath}
      cat << 'EOF' > ${nixHostSubstituterConfPath}
        ${nixHostSubstituterConfFile}
      EOF
    '';
  };

  nix.extraOptions = ''
    !include ${nixHostSubstituterConfPath}
  '';

  systemd.services.nix-daemon =
    let
      nixHostSubstituterService = "nix-host-substituter.service";
    in
    {
      wants = [ nixHostSubstituterService ];
      after = [ nixHostSubstituterService ];
    };
}
