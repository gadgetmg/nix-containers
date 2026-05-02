{
  nix2container,
  redis-operator,
  imageSource ? "https://github.com/gadgetmg/nix-containers",
}: let
  name = "ghcr.io/gadgetmg/redis-operator";
  config = {
    entrypoint = [
      "${redis-operator}/bin/redisoperator"
    ];
    Labels."org.opencontainers.image.source" = imageSource;
  };
in {
  latest = nix2container.buildImage {
    inherit name config;
    tag = "latest";
  };
  ${redis-operator.version} = nix2container.buildImage {
    inherit name config;
    tag = redis-operator.version;
  };
}
