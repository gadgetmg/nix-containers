{
  dockerTools,
  lib,
  mesa,
  nix2container,
  wolf,
  imageSource ? "https://github.com/gadgetmg/nix-containers",
}:
nix2container.buildImage {
  name = "ghcr.io/gadgetmg/wolf";
  tag = "stable";
  maxLayers = 120;
  copyToRoot = [
    dockerTools.caCertificates
  ];
  config = {
    entrypoint = [(lib.getExe' wolf "wolf")];
    Volumes = {
      "/run/user/wolf" = {};
    };
    Env = [
      "__EGL_VENDOR_LIBRARY_FILENAMES=${mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
      "GBM_BACKENDS_PATH=${lib.makeSearchPathOutput "lib" "lib/gbm" [mesa]}"
      "LIBVA_DRIVERS_PATH=${lib.makeSearchPathOutput "out" "lib/dri" [mesa]}"
      "XDG_RUNTIME_DIR=/run/user/wolf"
      "WOLF_CFG_FILE=/etc/wolf/cfg/config.toml"
      "WOLF_PRIVATE_KEY_FILE=/etc/wolf/cfg/key.pem"
      "WOLF_PRIVATE_CERT_FILE=/etc/wolf/cfg/cert.pem"
    ];
    Labels."org.opencontainers.image.source" = imageSource;
  };
}
