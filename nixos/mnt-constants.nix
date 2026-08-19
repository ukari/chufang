rec {
  hostNixRoot = "/mnt/host-nix";
  hostNixMnt = "${hostNixRoot}/nix";
  imageNixMnt = "/opt/image-nix";
  persistNixMnt = "/mnt/persist-nix";
  
  hostNixRegistryMnt = "/mnt/host-nix-registry.json";

  secretsDir = "/var/secrets/chufang";
  nixAccessTokensSecretsDir = "${secretsDir}/nix-access-tokens";
}