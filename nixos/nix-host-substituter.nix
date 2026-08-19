{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  isTemplateUnitMode = config.chufang.nix.isTemplateUnitMode;

  mntConstants = import ./mnt-constants.nix;
  hostNixRoot = mntConstants.hostNixRoot;
  hostNixMnt = mntConstants.hostNixMnt;
  hostNixStore = "${hostNixMnt}/store";
  hostNixRegistryMnt = mntConstants.hostNixRegistryMnt;

  runtimeDirName = "chufang/nix-host-substituter";
  runtimeDir = "/run/${runtimeDirName}";
  dynamicNixRegistryJsonPath = "${runtimeDir}/dynamic-nix-registry.json";

  nixHostSubstituterConfPath = "${runtimeDir}/host-nix.conf";
  ## priority for flake registry list: user, system, global[*]
  ## flake-registry = ${dynamicNixRegistryJsonPath}
  nixHostSubstituterConfFile = ''
    extra-experimental-features = read-only-local-store
    extra-substituters = local?root=${hostNixRoot}&read-only=true&trusted=true&priority=1
    extra-trusted-substituters = local?root=${hostNixRoot}&read-only=true&trusted=true
  '';
in
{
  imports = [
    ./core-options.nix
  ];
  config = lib.mkMerge [
    ({
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
          ln -sf ${dynamicNixRegistryJsonPath} /etc/nix/registry.json
        '';
      };

      nix.extraOptions = ''
        !include ${nixHostSubstituterConfPath}
      '';
    })

    (
      let
        nixHostSubstituterService = "nix-host-substituter.service";
        wants = [
          nixHostSubstituterService
        ];
        after = [
          nixHostSubstituterService
        ];
      in
      {
        systemd.services.nix-daemon = lib.mkIf (!isTemplateUnitMode) {
          inherit wants after;
        };

        systemd.services."nix-daemon@" = lib.mkIf isTemplateUnitMode {
          inherit wants after;
        };
      }
    )
  ];
}
