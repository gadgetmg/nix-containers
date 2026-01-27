build IMAGE:
  nix build \#\"{{IMAGE}}\"

login:
  skopeo login --username "$REGISTRY_USER" --password "$REGISTRY_PASSWORD" "$REGISTRY"

push IMAGE: login (build IMAGE)
  skopeo copy --insecure-policy docker-archive://$(readlink result) docker://$REGISTRY/$REGISTRY_USER/{{IMAGE}}

push-all:
  nix flake show --json | jq  '.packages."x86_64-linux"|keys[]' | xargs -I {} just push {}

load IMAGE: (build IMAGE)
  docker load -i result
