_: {
  perSystem = {
    inputs',
    pkgs,
    ...
  }: let
    buildImage = tag:
      inputs'.nix2container.packages.nix2container.buildImage {
        inherit tag;
        name = "ghcr.io/gadgetmg/wolf";
        copyToRoot = [
          pkgs.dockerTools.caCertificates
        ];
        config = {
          entrypoint = [(pkgs.lib.getExe' pkgs.wolf "wolf")];
          Env = [
            "__EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
            "GBM_BACKENDS_PATH=${pkgs.lib.makeSearchPathOutput "lib" "lib/gbm" [pkgs.mesa]}"
            "LIBVA_DRIVERS_PATH=${pkgs.lib.makeSearchPathOutput "out" "lib/dri" [pkgs.mesa]}"
            "XDG_RUNTIME_DIR=/run/user/wolf"
            "WOLF_CFG_FILE=/etc/wolf/cfg/config.toml"
            "WOLF_PRIVATE_KEY_FILE=/etc/wolf/cfg/key.pem"
            "WOLF_PRIVATE_CERT_FILE=/etc/wolf/cfg/cert.pem"
          ];
          Labels."org.opencontainers.image.source" = "https://github.com/gadgetmg/nix-containers";
        };
      };
    tags = [
      "latest"
      "stable"
      pkgs.wolf.version
      "nixos${pkgs.lib.version}"
      "${pkgs.wolf.version}-nixos${pkgs.lib.version}"
    ];
  in {
    packages = builtins.foldl' (acc: tag:
      acc
      // {
        "wolf:${tag}" = buildImage tag;
      }) {}
    tags;
  };
}
