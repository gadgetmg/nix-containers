_: {
  perSystem = {
    inputs',
    pkgs,
    ...
  }: let
    buildImage = tag:
      inputs'.nix2container.packages.nix2container.buildImage {
        inherit tag;
        name = "ghcr.io/gadgetmg/redis-operator";
        maxLayers = 120;
        config = {
          Entrypoint = ["${pkgs.redis-operator}/bin/redisoperator"];
          Labels."org.opencontainers.image.source" = "https://github.com/gadgetmg/nix-containers";
        };
      };
    tags = [
      "latest"
      pkgs.redis-operator.version
      "nixos${pkgs.lib.version}"
      "${pkgs.redis-operator.version}-nixos${pkgs.lib.version}"
    ];
  in {
    packages = builtins.foldl' (acc: tag:
      acc
      // {
        "redis-operator:${tag}" = buildImage tag;
      }) {}
    tags;
  };
}
