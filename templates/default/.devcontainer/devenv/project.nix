{
  pkgs,
  lib,
  config,
  ...
}:
{
  packages = with pkgs; [
    gitingest
  ];

  enterShell = ''
    echo "🫕 Chufang has been already!"
  '';
}
