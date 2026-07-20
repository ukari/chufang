{ lib, config, ... }:
let
  splitPath = path: lib.filter (s: s != "" && s != ".") (lib.splitString "/" path);

  stripCommonPrefix =
    p1: p2:
    if p1 == [ ] || p2 == [ ] || builtins.head p1 != builtins.head p2 then
      {
        fromRest = p1;
        toRest = p2;
      }
    else
      stripCommonPrefix (builtins.tail p1) (builtins.tail p2);

  relativeFromTo =
    from: to:
    let
      fromParts = splitPath from;
      toParts = splitPath to;

      stripped = stripCommonPrefix fromParts toParts;

      upCount = builtins.length stripped.fromRest;
      upParts = builtins.genList (_: "..") upCount;

      allParts = upParts ++ stripped.toRest;
    in
    if allParts == [ ] then "." else builtins.concatStringsSep "/" allParts;

  projectPath = config.devenv.root;
  projectName = builtins.baseNameOf projectPath;
  scoped = name: "${projectName}-\${devcontainerId}-${name}";
in
{
  inherit relativeFromTo scoped;
}
