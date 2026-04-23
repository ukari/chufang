{
  pkgs,
  config,
  ...
}:
let
  ctx = pkgs.callPackage ../lib/mk-context.nix { inherit config; };
  user = ctx.user;
  setupUidMap = ''
    MAX_UID=$(awk '{print $1 + $3 - 1}' /proc/self/uid_map | sort -nr | head -n 1)
    START_UID=2000
    LEN_UID=$((MAX_UID - START_UID))
    echo "${user}:$START_UID:$LEN_UID" | sudo tee /etc/subuid
  '';

  setupGidMap = ''
    MAX_GID=$(awk '{print $1 + $3 - 1}' /proc/self/gid_map | sort -nr | head -n 1)
    START_GID=2000
    LEN_GID=$((MAX_GID - START_GID))
    echo "${user}:$START_GID:$LEN_GID" | sudo tee /etc/subgid
  '';

  debianPamProfile = pkgs.writeText "xdg-pam-profile" ''
    Name: XDG PAM Config
    Default: yes
    Priority: 128
    Session-Type: Additional
    Session:
      required pam_xdg.so
  '';

  setupXdgPamConf = ''
    sudo cp ${debianPamProfile} /usr/share/pam-configs/xdg-pam
    sudo DEBIAN_FRONTEND=noninteractive pam-auth-update --enable xdg-pam
  '';
in {
  packages = with pkgs; [
    #shadow
    #pam_xdg
    podman
    act
  ];

  devcontainer.settings = {
    runArgs = [
      "--cap-add=SYS_ADMIN"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
      "--security-opt=seccomp=unconfined"
      "--device=/dev/fuse" 
    ];

    features = {
        "ghcr.io/devcontainers-extra/features/apt-get-packages:1" = {
        packages = [

        ];
        };
    };

    postCreateCommand = ''
      ${setupUidMap}
      ${setupGidMap}
      ${setupXdgPamConf}
    '';
  };
}