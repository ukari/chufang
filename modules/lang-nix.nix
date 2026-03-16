{ pkgs, config, ... }:
let
  lspPkg = config.languages.nix.lsp.package;

  lspName = lspPkg.name or "";

  lspSettingsMap = {
    "nil" = {
      "nil" = {
        "nix" = {
          "flake" = {
            "autoArchive" = true;
            "autoEvalInputs" = false;
          };
        };
      };
    };
  };

  currentLspSettings = lspSettingsMap.${lspName} or { };
in
{
  languages.nix = with pkgs; {
    enable = true;
    lsp.enable = lib.mkDefault true;
    lsp.package = lib.mkDefault nil;
  };

  packages = with pkgs; [
    nil
  ];

  devcontainer.settings = with pkgs; {
    customizations = {
      vscode = {
        extensions = [
          "jnoortheen.nix-ide"
        ];

        settings = {
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = lib.getExe lspPkg;
          "nix.serverSettings" = currentLspSettings;
        };
      };
    };
  };
}
