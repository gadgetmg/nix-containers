{
  steam,
  dockerTools,
  callPackage,
  compositor ? "sway",
  ...
}: let
  extraSwayConfig = ''
    for_window [instance="steamwebhelper"] border none
    for_window [instance="steam_app_.*"] fullscreen enable
    for_window [app_id="steam_app_.*"] fullscreen enable
  '';
in
  callPackage ../build-gow-image {
    name = "steam";
    inherit compositor extraSwayConfig;
    extraPkgs = [dockerTools.caCertificates];
    runApp = "${steam}/bin/steam -bigpicture";
  }
