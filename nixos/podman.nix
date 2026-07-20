{ config, pkgs, ... }: {

  imports = [
    ./xdg-compat.nix
  ];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  systemd.user.services.podman-restart = {
    enable = true;
    wantedBy = [ "default.target" ];
  };

  environment.etc."containers/registries.conf.d/01-short-name.conf".text = ''
    short-name-mode = "disabled"
  '';

  environment.etc."containers/containers.conf.d/01-subnet-pools.conf".text = ''
    [network]
    default_subnet_pools = [
      { "base" = "172.17.0.0/12", "size" = 24 }
    ]
  '';

  systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
}
