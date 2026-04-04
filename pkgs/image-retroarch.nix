{
  dockerTools,
  gamesOnWhalesTools,
  lib,
  retroarch-bare,
  xdg-utils,
  xset,
  ...
}: let
  retroarch' = retroarch-bare.override {
    withGamemode = false;
  };
in
  gamesOnWhalesTools.buildImages rec {
    name = "ghcr.io/gadgetmg/retroarch";
    pkg = retroarch';
    cmd = lib.getExe pkg;
    extraPkgs = [dockerTools.caCertificates xdg-utils xset];
  }
