{
  pkgs,
  lib,
  inputs,
  user,
  scoped,
  hostNixMnt,
}:
let
  hostNix = "${hostNixMnt}/nix";
  hostNixStore = "${hostNix}/store";
  imageNixMnt = "/opt/image-nix";
  imageNix = "${imageNixMnt}/nix";
  imageNixStore = "${imageNix}/store";
  #   imageNixVar = "${imageNix}/var";
  persistNixMnt = "/mnt/persist-nix";
  persistNix = "${persistNixMnt}/nix";
  persistNixStoreUpper = "${persistNixMnt}/store-upper";
  persistNixStoreWork = "${persistNixMnt}/store-work";
  persistNixStoreMerge = "${persistNix}/store";
  persistNixVar = "${persistNix}/var";

  githubTokenSecretPath = ".devcontainer/GITHUB_TOKEN.secret";
  secretsDir = "/var/secrets";
  nixAccessTokenConfPath = "${secretsDir}/nix-access-tokens.conf";

  tasks = {
    "infra:secrets:GITHUB_TOKEN" = {
      exec = ''
        if TOKEN=$(secretspec get GITHUB_TOKEN 2>/dev/null); then
          echo $TOKEN > ${githubTokenSecretPath}
        fi
      '';
      status = ''
        CUR_TOKEN=$(secretspec get GITHUB_TOKEN)
        if [ -f ${githubTokenSecretPath} ]; then
          OLD_TOKEN=$(cat ${githubTokenSecretPath})
          if [ "$CUR_TOKEN" = "$OLD_TOKEN" ]; then
            exit 0
          else
            exit 1
          fi
        else
          exit 1
        fi
      '';
      before = [ "devenv:enterShell" ];
    };
  };

  packages = with pkgs; [
    fuse-overlayfs
  ];

  features = {
    "ghcr.io/devcontainers-extra/features/apt-get-packages:1" = {
      packages = [
        # "fuse-overlayfs"
      ];
    };
  };

  runArgs = [
    "--userns=keep-id"
    "--device=/dev/fuse"
    "--cap-add=SYS_ADMIN"
    "--security-opt=apparmor=unconfined"
  ];

  mounts = [
    {
      source = "/nix";
      target = hostNix;
      type = "bind";
      readonly = true;
    }
    {
      source = scoped "nix-persist";
      target = persistNixMnt;
      type = "volume";
    }
  ];

  overlayStore = "local-overlay://?lower-store=${
    lib.strings.escapeURL ("local?root=" + imageNixMnt + "&read-only=true")
  }&upper-layer=${persistNixStoreUpper}&state=${persistNixVar}&check-mount=false";

  containerEnv = {
    NIX_REMOTE = "daemon";
  };

  setupMnt = ''
    sudo mkdir -p ${imageNixMnt} ${imageNix}
    sudo mkdir -p ${persistNixStoreUpper} ${persistNixStoreWork} ${persistNixStoreMerge}
    sudo mkdir -p ${persistNixVar}
    if [ "$(stat -c '%U:%G' ${persistNixStoreUpper})" != "root:nixbld" ]; then
      sudo chown -R root:nixbld ${persistNixStoreUpper} ${persistNixStoreWork}
      sudo chmod -R 775 ${persistNixStoreUpper} ${persistNixStoreWork}
    fi
  '';

  setupNixAccessTokenConf = ''
    sudo mkdir -p ${secretsDir}
    if [ -f ${githubTokenSecretPath} ]; then
      echo "access-tokens = github.com=`cat ${githubTokenSecretPath}`" | sudo tee ${nixAccessTokenConfPath} >/dev/null
      sudo chmod 600 ${nixAccessTokenConfPath}
    else
      sudo rm -f ${nixAccessTokenConfPath}
    fi
  '';

  setupOverlay = ''
    if [ -S /nix/var/nix/daemon-socket/socket ] && ps -ww -ef | grep -v grep | grep -F "nix-daemon" | grep -F "${overlayStore}" > /dev/null; then
      echo "Nix Daemon is already running with Overlay Store configuration."
    else
      if ! mountpoint -q "${imageNix}"; then
        sudo mount --bind /nix ${imageNix}
        sudo mount -o remount,ro,bind ${imageNix}
      fi

      sudo rm -rf ${persistNixStoreWork}/*

      #sudo fuse-overlayfs \
      #  -o allow_other \
      sudo mount -t overlay overlay \
        -o userxattr \
        -o lowerdir=${imageNixStore} \
        -o upperdir=${persistNixStoreUpper} \
        -o workdir=${persistNixStoreWork} \
        /nix/store

      echo "Restarting Nix Daemon to apply Overlay Store..."

      sudo pkill nix-daemon || true
      for _ in {1..5}; do pgrep nix-daemon >/dev/null || break; sleep 0.2; done
      sudo rm -f /nix/var/nix/daemon-socket/socket

      if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      echo "Starting Nix Daemon with overlay store: ${overlayStore}"
      sudo -H sh -c "exec /nix/var/nix/profiles/default/bin/nix-daemon --store '${overlayStore}' > /tmp/nix-daemon.log 2>&1 &"

      echo "Waiting for Nix Daemon socket..."
      for i in {1..10}; do
        if [ -S /nix/var/nix/daemon-socket/socket ]; then
          echo "Nix Daemon is back online."
          break
        fi
        sleep 0.5
      done
      nix store info && echo "Overlay Store is reachable"
    fi
  '';

  nixpkgsParams = lib.concatStringsSep "&" (
    (lib.optional (inputs.nixpkgs ? rev) "rev=${inputs.nixpkgs.rev}")
    ++ (lib.optional (inputs.nixpkgs ? narHash) "narHash=${inputs.nixpkgs.narHash}")
    ++ (lib.optional (
      inputs.nixpkgs ? lastModified
    ) "lastModified=${toString inputs.nixpkgs.lastModified}")
  );
  nixpkgsQuery = if nixpkgsParams != "" then "?${nixpkgsParams}" else "";

  setupRegistry = ''
    nix registry add nixpkgs "path:${hostNixMnt}${pkgs.path}${nixpkgsQuery}"
  '';

  nixConfText = ''
    extra-experimental-features = nix-command flakes read-only-local-store local-overlay-store
    substituters = local?root=${hostNixMnt}&read-only=true&trusted=true https://cache.nixos.org/
    trusted-substituters = local?root=${hostNixMnt}&read-only=true&trusted=true

    accept-flake-config = true
    build-users-group = nixbld
    trusted-users = root ${user}
    sandbox = false

    nix-path = nixpkgs=${hostNixMnt}${pkgs.path}
    !include ${nixAccessTokenConfPath}
  '';

  initNixConf = ''
    mkdir -p /etc/nix
    sudo tee /etc/nix/nix.conf <<EOF
    ${nixConfText}
    EOF
  '';

in
{
  inherit
    hostNix
    persistNixMnt
    tasks
    packages
    runArgs
    mounts
    containerEnv
    features
    setupMnt
    setupNixAccessTokenConf
    setupOverlay
    setupRegistry
    initNixConf
    ;
}
