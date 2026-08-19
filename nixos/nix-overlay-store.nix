{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  isTemplateUnitMode = config.chufang.nix.isTemplateUnitMode;
  isLix = config.chufang.nix.isLix;

  mntConstants = import ./mnt-constants.nix;
  imageNixMnt = mntConstants.imageNixMnt;
  imageNix = "${imageNixMnt}/nix";
  imageNixStore = "${imageNix}/store";
  /*
    oci image layer: /nix/store -[mount bind, ro]-> /opt/image-nix/nix-store
    lower: ${imageNixStore} /opt/image-nix/nix/store, upper: ${imageNixStoreUpper} /opt/image-nix/store-upper, ${imageNixStoreWork} work: /opt/image-nix/store-work -[mount overlay]-> /opt/image-nix/store-rw
    lower: /opt/image-nix/store-rw, upper: ${persistNixStoreUpper}, work: ${persistNixStoreWork} -[mount overlay]> os dir: /nix/store
  */
  imageNixStoreRW = "${imageNixMnt}/store-rw";
  imageNixStoreUpper = "${imageNixMnt}/store-upper";
  imageNixStoreWork = "${imageNixMnt}/store-work";

  persistNixMnt = mntConstants.persistNixMnt;
  persistNix = "${persistNixMnt}/nix";
  persistNixStoreUpper = "${persistNixMnt}/store-upper";
  persistNixStoreWork = "${persistNixMnt}/store-work";
  # persistNixStoreMerge = "${persistNix}/store";
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
  imports = [
    ./core-options.nix
  ];
  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !config.chufang.nix.isLix;
          message = ''

            [nix-overlay-store] Build-time Blocked:
            Lix is not supported by this module because it lacks 'local-overlay-store' (SQLite DB merging).
            Please configure standard C++ Nix in your configuration instead, for example:
              
              nix.package = pkgs.nix;

            (Reference: [~~Abandoned~~] https://gerrit.lix.systems/c/lix/+/2859)
          '';
        }
      ];
    }

    ({
      # environment.systemPackages = with pkgs; [
      #   fuse-overlayfs
      # ];

      systemd.tmpfiles.rules = [
        /*
          nix/src/libstore/local-store.cc https://github.com/NixOS/nix/blob/eab63a0eb6f63a9e224ab036841a2c05d9cf69b1/src/libstore/local-store.cc#L124
          here calls createDirs() in config->stateDir.get():
            ...
            , linksDir(config->realStoreDir.get() / ".links")
            , tempRootsDir(config->stateDir.get() / "temproots")
            ...
                createDirs(linksDir);
                createDirs(tempRootsDir);
        */
        "d /nix/var/nix/temproots 1777 root root -"
        # auto create with read-write permission "d /nix/store/.links 0755 root root -"

        "d ${imageNixMnt} 0755 root root -"
        "d ${imageNix} 0755 root root -"
        "d ${imageNixStoreUpper} 0755 root root -"
        "D ${imageNixStoreWork} 0755 root root -"

        "d ${persistNixStoreUpper} 0775 root nixbld -"
        "D ${persistNixStoreWork} 0775 root nixbld -"
        #"d ${persistNixStoreMerge} 0755 root root -"
        "d ${persistNixVar} 0755 root root -"
      ];

      systemd.mounts = [
        {
          what = "/nix";
          where = imageNix;
          type = "none";
          options = "bind";
          unitConfig = {
            ConditionPathIsMountPoint = [
              persistNixMnt
            ];
          };
          wantedBy = [ ];
        }
        # (
        #   let
        #     imageNixMount = "${utils.escapeSystemdPath imageNix}.mount";
        #   in
        #   {
        #     what = "overlay";
        #     where = "/nix/store";
        #     type = "overlay";

        #     options = lib.strings.concatStringsSep "," [
        #       "userxattr"
        #       "lowerdir=${imageNixStore}"
        #       "upperdir=${persistNixStoreUpper}"
        #       "workdir=${persistNixStoreWork}"
        #     ];

        #     unitConfig = {
        #       ConditionPathIsMountPoint = [
        #         imageNix
        #       ];
        #     };

        #     requires = [ imageNixMount ];
        #     after = [ imageNixMount ];
        #     wantedBy = [ ];
        #   }
        # )
      ];

      systemd.services.nix-overlay-store =
        let
          imageNixMount = "${utils.escapeSystemdPath imageNix}.mount";
          #nixStoreMount = "${utils.escapeSystemdPath "/nix/store"}.mount";
        in
        {
          wantedBy = [ ];
          requires = [ imageNixMount ];
          after = [ imageNixMount ];
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

          script = let
              
          in ''
            # if ! ${pkgs.util-linux}/bin/findmnt ${imageNixStoreUpper} | grep -q "tmpfs"; then
            #   ${pkgs.util-linux}/bin/mount -t tmpfs tmpfs "${imageNixStoreUpper}"
            # fi
            # if ! ${pkgs.util-linux}/bin/findmnt ${imageNixStoreWork} | grep -q "tmpfs"; then
            #   ${pkgs.util-linux}/bin/mount -t tmpfs tmpfs "${imageNixStoreWork}"
            # fi
            # if ! ${pkgs.util-linux}/bin/findmnt -n -o OPTIONS ${imageNixStoreRW} | grep -q "${imageNixStoreUpper}"; then
            #   ${pkgs.util-linux}/bin/mount -t overlay overlay \
            #     -o userxattr \
            #     -o lowerdir=${imageNixStore} \
            #     -o upperdir=${imageNixStoreUpper} \
            #     -o workdir=${imageNixStoreWork} \
            #     ${imageNixStoreRW}
            # fi

            if ! ${pkgs.util-linux}/bin/findmnt -n -o OPTIONS /nix/store | grep -q "${persistNixStoreUpper}"; then
              ${pkgs.util-linux}/bin/mount -t overlay overlay \
                -o userxattr \
                -o lowerdir=${imageNixStore} \
                -o upperdir=${persistNixStoreUpper} \
                -o workdir=${persistNixStoreWork} \
                /nix/store
              ${config.nix.package}/bin/nix-store --verify || true
            fi
            cat << 'EOF' > ${nixOverlayStoreConfPath}
            ${nixOverlayStoreConfFile}
            EOF
          '';
        };

      nix.extraOptions = ''
        !include ${nixOverlayStoreConfPath}
      '';
    })

    (
      let
        nixOverlayStoreService = "nix-overlay-store.service";
        wants = [ nixOverlayStoreService ];
        after = [ nixOverlayStoreService ];
        serviceConfig = {
          ExecStart =
            let
              templateUnitArgs =
                if isTemplateUnitMode then
                  if isLix then
                    [
                      "--for-socket-activation"
                    ]
                  else
                    [
                      "--stdio"
                    ]
                else
                  [ ];
            in
            lib.mkForce [
              # exec ${pkgs.nix}/bin/nix-daemon --extra-experimental-features local-overlay-store --store '${overlayStore}'
              # exec ${config.nix.package}/bin/nix-daemon ${lib.escapeShellArgs templateUnitArgs} --store '${overlayStore}'
              ""
              (pkgs.writeShellScript "nix-overlay-store-daemon" ''
                if ${pkgs.util-linux}/bin/mountpoint -q /nix/store && { ${pkgs.util-linux}/bin/findmnt /nix/store | grep -q "${imageNixStore}"; }; then
                    exec ${config.nix.package}/bin/nix-daemon ${lib.escapeShellArgs templateUnitArgs} --store '${overlayStore}'
                else
                    exec ${config.nix.package}/bin/nix-daemon ${lib.escapeShellArgs templateUnitArgs}
                fi
              '')
            ];
        };
      in
      {
        systemd.services.nix-daemon = lib.mkIf (!isTemplateUnitMode) {
          inherit wants after serviceConfig;
        };

        systemd.services."nix-daemon@" = lib.mkIf isTemplateUnitMode {
          inherit wants after serviceConfig;
        };
      }
    )
  ];
}
