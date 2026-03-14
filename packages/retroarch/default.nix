{
  retroarch-bare,
  dockerTools,
  xdg-utils,
  xset,
  callPackage,
  compositor ? "sway",
  ...
}: let
  retroarch' = retroarch-bare.override {
    withGamemode = false;
  };
  extraSwayConfig = ''
  '';
in
  callPackage ../build-gow-image {
    name = "retroarch";
    inherit compositor extraSwayConfig;
    extraPkgs = [dockerTools.caCertificates xdg-utils xset];
    runApp = "${retroarch'}/bin/retroarch";
  }
