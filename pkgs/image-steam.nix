{
  dockerTools,
  gamesOnWhalesTools,
  lib,
  steam,
  ...
}: let
  extraSwayConfig = ''
    for_window [instance="steamwebhelper"] border none
    for_window [instance="steam_app_.*"] fullscreen enable
    for_window [app_id="steam_app_.*"] fullscreen enable
  '';
in
  gamesOnWhalesTools.buildImages rec {
    name = "ghcr.io/gadgetmg/steam";
    pkg = steam;
    cmd = "${lib.getExe pkg} -bigpicture";
    extraPkgs = [dockerTools.caCertificates];
    inherit extraSwayConfig;
  }
