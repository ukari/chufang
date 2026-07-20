{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  constants = import ./constants.nix;
  imageNixMnt = constants.imageNixMnt;
  imageNix = "${imageNixMnt}/nix";
  imageNixStore = "${imageNix}/store";
  persistNixMnt = constants.persistNixMnt;
  persistNix = "${persistNixMnt}/nix";
  persistNixStoreUpper = "${persistNixMnt}/store-upper";
  persistNixStoreWork = "${persistNixMnt}/store-work";
  persistNixStoreMerge = "${persistNix}/store";
  persistNixVar = "${persistNix}/var";

  overlayStore = "local-overlay://?lower-store=${
    lib.strings.escapeURL ("local?root=" + imageNixMnt + "&read-only=true")
  }&upper-layer=${persistNixStoreUpper}&state=${persistNixVar}&check-mount=false";

  runtimeDirName = "chufang/nix-overlay-store";
  runtimeDir = "/run/${runtimeDirName}";

  nixOverlayStoreConfPath = "${runtimeDir}/overlay-store.conf";
  nixOverlayStoreConfFile = ''
    extra-experimental-features = local-overlay-store read-only-local-store
  '';

in
{
  environment.systemPackages = with pkgs; [
    fuse-overlayfs
  ];

  systemd.tmpfiles.rules = [
    /*
      nix/src/libstore/local-store.cc https://github.com/NixOS/nix/blob/eab63a0eb6f63a9e224ab036841a2c05d9cf69b1/src/libstore/local-store.cc#L124
      here calls createDirs() in config->stateDir.get():
        ...
        , tempRootsDir(config->stateDir.get() / "temproots")
        ...
            createDirs(tempRootsDir);
    */
    "d /nix/var/nix/temproots 1777 root root -"

    "d ${imageNixMnt} 0755 root root -"
    "d ${imageNix} 0755 root root -"
    "d ${persistNixStoreUpper} 0775 root nixbld -"
    "D ${persistNixStoreWork} 0775 root nixbld -"
    "d ${persistNixStoreMerge} 0755 root root -"
    "d ${persistNixVar} 0755 root root -"
  ];

  systemd.mounts =

    [
      {
        what = "/nix";
        where = imageNix;
        type = "none";
        options = "bind,ro";
        unitConfig = {
          ConditionPathIsMountPoint = [
            persistNixMnt
          ];
        };
        wantedBy = [ ];
      }
      (
        let
          imageNixMount = "${utils.escapeSystemdPath imageNix}.mount";
        in
        {
          what = "overlay";
          where = "/nix/store";
          type = "overlay";

          options = lib.strings.concatStringsSep "," [
            "userxattr"
            "lowerdir=${imageNixStore}"
            "upperdir=${persistNixStoreUpper}"
            "workdir=${persistNixStoreWork}"
          ];

          unitConfig = {
            ConditionPathIsMountPoint = [
              imageNix
            ];
          };

          requires = [ imageNixMount ];
          after = [ imageNixMount ];
          wantedBy = [ ];
        }
      )
    ];

  systemd.services.nix-overlay-store =
    let
      nixStoreMount = "${utils.escapeSystemdPath "/nix/store"}.mount";
    in
    {
      wantedBy = [ ];
      requires = [ nixStoreMount ];
      after = [ nixStoreMount ];
      before = [ ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = runtimeDirName;
      };

      unitConfig = {
        ConditionPathIsMountPoint = [
          "/nix/store"
        ];
      };

      script = ''
        cat << 'EOF' > ${nixOverlayStoreConfPath}
          ${nixOverlayStoreConfFile}
        EOF
      '';
    };

  nix.extraOptions = ''
    !include ${nixOverlayStoreConfPath}
  '';

  systemd.services.nix-daemon =
    let
      nixOverlayStoreService = "nix-overlay-store.service";
    in
    {
      wants = [ nixOverlayStoreService ];
      after = [ nixOverlayStoreService ];

      # exec ${pkgs.nix}/bin/nix-daemon --extra-experimental-features local-overlay-store --store '${overlayStore}'
      serviceConfig.ExecStart = lib.mkForce [
        ""
        (pkgs.writeShellScript "nix-overlay-store-daemon" ''
          if ${pkgs.util-linux}/bin/mountpoint -q /nix/store && [ "$(${pkgs.util-linux}/bin/findmnt -n -o FSTYPE /nix/store)" = "overlay" ]; then
              exec ${pkgs.nix}/bin/nix-daemon --store '${overlayStore}'
          else
              exec ${config.nix.package}/bin/nix-daemon
          fi
        '')
      ];
    };
}
