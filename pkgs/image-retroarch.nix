{
  dockerTools,
  gamesOnWhalesTools,
  retroarch-bare,
  xdg-utils,
  xset,
  ...
}: let
  retroarch' = retroarch-bare.override {
    withGamemode = false;
  };
in
  gamesOnWhalesTools.buildImages {
    name = "ghcr.io/gadgetmg/retroarch";
    pkg = retroarch';
    Cmd = ["retroarch"];
    extraPkgs = [dockerTools.caCertificates xdg-utils xset];
  }
