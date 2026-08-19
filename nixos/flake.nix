{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    let
      modulePaths = [
        ./configuration.nix
        ./nix-registry.nix
        ./git.nix

        ./core-options.nix
        

        ./podman.nix

        ./ld-compat.nix
        ./fhs-compat.nix
        ./xdg-compat.nix
        ./vscode-compat.nix

        ./direnv.nix
        ./devenv.nix

        ./nix-access-tokens.nix
        ./nix-daemon-socket.nix
        ./nix-host-substituter.nix
        ./nix-overlay-store.nix
      ];

       attributeSetPaths = [
        ./mnt-constants.nix
      ];

      sourceFiles = modulePaths ++ attributeSetPaths;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      flake = {
        nixosConfigurations.nixos-rebuild-base = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = modulePaths;
        };
      };
      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        let
          nixosCfg = inputs.self.nixosConfigurations.nixos-rebuild-base;
          closureInfo = pkgs.closureInfo {
            rootPaths = [ nixosCfg.config.system.build.toplevel ];
          };
          nixpkgsRev = inputs.nixpkgs.rev or "nixos-unstable";
          nixosEnvList = pkgs.lib.mapAttrsToList (
            name: value: "${name}=${builtins.toString value}"
          ) nixosCfg.config.environment.variables;
          makeTargetFlake =
            modules:
            let
              makeModuleStr = path: "./${builtins.baseNameOf path}";
            in
            ''
              {
                inputs = {
                  nixpkgs.url = "github:NixOS/nixpkgs/${nixpkgsRev}";

                  flake-parts = {
                  url = "github:hercules-ci/flake-parts";
                  inputs.nixpkgs-lib.follows = "nixpkgs";
                  };
                };

                outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
                  systems = [ "${system}" ];

                  flake = let
                    mkNixos = modules: inputs.nixpkgs.lib.nixosSystem {
                      system = "x86_64-linux";
                      specialArgs = { inherit inputs; };
                      modules = modules;
                    };
                  in {
                    nixosConfigurations.dev = mkNixos [
                      ${pkgs.lib.concatStringsSep "\n        " (map makeModuleStr modules)}
                    ];
                  };
                };
              }
            '';
          targetFlake = makeTargetFlake modulePaths;
          makeCopyContentStr = filename: content: ''
            cat << 'EOF' > /etc/nixos/${filename}
            ${content}
            EOF
          '';
          makeCopyFileStr =
            filename: path:
            let
              content = builtins.readFile path;
            in
            makeCopyContentStr filename content;
          copyContentStrList = [
            (makeCopyContentStr "flake.nix" targetFlake)
          ]
          ++ (map (
            path:
            let
              filename = builtins.baseNameOf path;
            in
            makeCopyFileStr filename path
          ) sourceFiles);

          validUsers = pkgs.lib.filterAttrs (n: u: u.uid != null) nixosCfg.config.users.users;
          validGroups = pkgs.lib.filterAttrs (n: g: g.gid != null) nixosCfg.config.users.groups;
          groupLines =
            let
              mkMembers = ms: builtins.concatStringsSep "," ms;
            in
            pkgs.lib.mapAttrsToList (n: g: "${n}:x:${toString g.gid}:${mkMembers g.members}") validGroups;
          passwdLines = pkgs.lib.mapAttrsToList (
            n: u:
            let
              gid = nixosCfg.config.users.groups.${u.group}.gid;
              home = if u.home != null then u.home else "/var/empty";
            in
            "${n}:x:${toString u.uid}:${toString gid}:${u.description}:${home}:/bin/sh"
          ) validUsers;
          extraGroupContent = pkgs.lib.concatStringsSep "\n" groupLines;
          extraPasswdContent = pkgs.lib.concatStringsSep "\n" passwdLines;
          extraShadowContent = pkgs.lib.concatMapStringsSep "\n" (n: "${n}:!:1::::::") (
            builtins.attrNames validUsers
          );
          extraShadowSetup = ''
            cat ${pkgs.writeText "extra-group" extraGroupContent} >> /etc/group
            cat ${pkgs.writeText "extra-passwd" extraPasswdContent} >> /etc/passwd
            cat ${pkgs.writeText "extra-shadow" extraShadowContent} >> /etc/shadow
          '';
        #   sudoersSetup =
        #     let
        #       wheelSudoerLine = "%wheel  ALL=(ALL:ALL)    NOPASSWD:SETENV: ALL";
        #     in
        #     ''
        #       mkdir -p /etc/sudoers.d
        #       cat ${pkgs.writeText "wheel-sudoer" wheelSudoerLine} > /etc/sudoers.d/wheel
        #       chmod 440 /etc/sudoers.d/wheel
        #     '';
        in
        {
          packages.nixos-rebuild-base = pkgs.dockerTools.buildLayeredImage {
            name = "nixos-rebuild-base";
            tag = "latest";

            contents = [
              nixosCfg.config.system.build.toplevel
              pkgs.coreutils
              pkgs.bashInteractive
            ];
            config = {
              User = "0:0";
              Cmd = [ "${nixosCfg.config.system.build.toplevel}/init" ];
              Env = [
              ]
              ++ nixosEnvList;
            };

            fakeRootCommands = with pkgs; ''
              #!${runtimeShell}
              ${nix}/bin/nix-store --load-db < ${closureInfo}/registration
              rm -rf /etc
              mkdir -p /proc /sys /dev /etc
              mkdir -p /etc/nixos

              ${lib.concatStringsSep "\n" copyContentStrList}
              chmod 644 /etc/nixos/*
              ${dockerTools.shadowSetup}
              ${extraShadowSetup}
              
            '';
            # ${sudoersSetup}
            enableFakechroot = true;
          };

          packages.default = config.packages.nixos-rebuild-base;
        };
    };
}
