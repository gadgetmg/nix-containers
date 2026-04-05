build IMAGE:
  nix build \#\"{{IMAGE}}\"

copy-docker IMAGE: (build IMAGE)
  nix run \#\"{{IMAGE}}\".copyToDockerDaemon

copy-docker-all:
  nix flake show --json | jq  -r '.packages."x86_64-linux"|keys[]' | xargs -I {} just copy-docker {}

login:
  docker login ghcr.io

copy-registry IMAGE: (build IMAGE)
  nix run \#\"{{IMAGE}}\".copyToRegistry

copy-registry-all:
  nix flake show --json | jq  -r '.packages."x86_64-linux"|keys[]' | xargs -I {} just copy-registry {}
