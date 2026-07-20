## test nixbld
a.
```
nix build --impure --no-link --print-build-logs --expr 'let nixpkgs = builtins.getFlake "github:NixOS/nixpkgs/nixpkgs-unstable"; pkgs = nixpkgs.legacyPackages.${builtins.currentSystem}; in pkgs.runCommand "test-uid-full" {} "id > \$out; cat \$out"'
```

b.
```
nix build --impure -I nixpkgs=flake:nixpkgs --expr 'with import <nixpkgs> {}; runCommand "test-build" {} "sleep 30; touch \$out"'

ps aux | grep -E 'sleep|nixbld'
```

## test cgroup
```
nix build --impure --no-link --print-build-logs -I nixpkgs=flake:nixpkgs --expr 'with import <nixpkgs> {}; runCommand "test-cgroup" {} "cat /proc/self/cgroup > \$out; echo -e \"\\n=== MY CGROUP PATH ===\\n\$(cat \$out)\\n======================\\n\""'
```

### test vscode subUidRange for podman in podman
```
cat /etc/subuid
cat /etc/subuid
podman unshare cat /proc/self/uid_map
podman run --rm alpine id
```


## test require-drop-supplementary-groups
```
nix build --impure --no-link --print-build-logs -I nixpkgs=flake:nixpkgs --expr 'with import <nixpkgs> {}; runCommand "test-groups" {} "id -G > \$out; echo -e \"\\n=== ACTIVE GROUPS IN SANDBOX ===\\n\$(cat \$out)\\n================================\\n\""'
```