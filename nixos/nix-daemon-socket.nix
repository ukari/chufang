{
  config,
  lib,
  pkgs,
  ...
}:
let
  isLix = config.chufang.nix.isLix;
in
{
  imports = [
    ./core-options.nix
  ];

  config = lib.mkIf (!isLix) {
    systemd.sockets.nix-daemon = {
      conflicts = [ "nix-daemon.service" ];
      socketConfig.Accept = true;
    };

    /*
      https://github.com/NixOS/nix/blob/aafac2b8d93e3d9ecf05cafb4c446f8ae97347b8/misc/systemd/nix-daemon.service.in
       [Unit]
       Description=Nix Daemon
       Documentation=man:nix-daemon https://nixos.org/manual
       RequiresMountsFor=@storedir@
       RequiresMountsFor=@localstatedir@
       RequiresMountsFor=@localstatedir@/nix/db
       ConditionPathIsReadWrite=@localstatedir@/nix/daemon-socket

       [Service]
       ExecStart=@@bindir@/nix-daemon nix-daemon --daemon
       KillMode=process
       LimitNOFILE=1048576
       TasksMax=1048576
       Delegate=

       [Install]
       WantedBy=multi-user.target
    */
    /*
      https://github.com/lix-project/lix/blob/eb7009316b012d48a82735e36bc9485a32558658/misc/systemd/daemon%40.service.in
      [Unit]
      Description=Lix Daemon instance (@desc@)
      Documentation=man:nix-daemon https://docs.lix.systems/manual/lix/stable
      CollectMode=inactive-or-failed
      RequiresMountsFor=@storedir@
      RequiresMountsFor=@localstatedir@
      RequiresMountsFor=@localstatedir@/nix/db

      [Service]
      ExecStart=@@bindir@/nix-daemon nix-daemon --for-socket-activation
      CacheDirectory=nix
      LimitNOFILE=1048576
      TasksMax=1048576
      Delegate=yes
      DelegateSubgroup=supervisor
      Slice=system-lix-daemon-@slice@.slice
    */
    /*
      https://github.com/lix-project/lix/blob/37ff864b79671cead7704d5238383c090760fd7b/misc/systemd/nix-daemon.service.in
      [Unit]
      Description=Nix Daemon
      Documentation=man:nix-daemon https://docs.lix.systems/manual/lix/stable
      Conflicts=@conflicts@
      RequiresMountsFor=@storedir@
      RequiresMountsFor=@localstatedir@
      RequiresMountsFor=@localstatedir@/nix/db
      ConditionPathIsReadWrite=@localstatedir@/nix/daemon-socket

      [Service]
      ExecStart=@@bindir@/nix-daemon nix-daemon --daemon
      CacheDirectory=nix
      KillMode=process
      LimitNOFILE=1048576
      TasksMax=1048576
      Delegate=yes
      DelegateSubgroup=supervisor
    */
    systemd.services."nix-daemon@" = {
      description = "Nix Daemon instance";
      path = config.systemd.services.nix-daemon.path;
      environment = builtins.removeAttrs config.systemd.services.nix-daemon.environment [ "PATH" ];
      unitConfig = {
        CollectMode = "inactive-or-failed";
        RequiresMountsFor = [
          "/nix/store"
          "/nix/var"
          "/nix/var/nix/db"
        ];
        ConditionPathIsReadWrite = [ "/nix/var/nix/daemon-socket" ];
      };
      serviceConfig = {
        ExecStart = "${config.nix.package}/bin/nix-daemon --stdio";
        StandardInput = "socket";
        StandardOutput = "socket";
        StandardError = "journal";
        KillMode = "process";
        CacheDirectory = "nix";
        LimitNOFILE = 1048576;
        TasksMax = 1048576;
        Delegate = true;
        DelegateSubgroup = "supervisor";
      };
    };
  };
}
