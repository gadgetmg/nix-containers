{
  dockerTools,
  gamesOnWhalesTools,
  steam,
  buildFHSEnv,
  glibc,
  writeShellScript,
  ...
}: let
  extraSwayConfig = ''
    for_window [title=".*"] fullscreen enable
  '';
in
  gamesOnWhalesTools.buildImages {
    name = "ghcr.io/gadgetmg/steam";
    pkg = steam.override {
      buildFHSEnv = args:
        buildFHSEnv (args
          // {
            extraBuildCommands =
              (args.extraBuildCommands or "")
              + ''
                rm -f $out/usr/sbin/ldconfig
                cp ${glibc.bin}/bin/ldconfig $out/usr/sbin/ldconfig
              '';
          });
    };
    helperScript = writeShellScript "steam-helper.sh" ''
      function log() {
        echo "$(date +"[%Y-%m-%d %H:%M:%S]") $* [steam-helper] "
      }
      function shutdown_steam() {
        log "Shutting down Steam..."
        pkill steam
        exit 0
      }
      log "Starting D-Bus watcher for Steam shutdown..."
      dbus-monitor --system "interface='org.freedesktop.ConsoleKit.Manager'" | \
      while read -r line; do
        log "$line"
        if echo "$line" | grep -q "member=Stop"; then
          log "Detected 'Stop' D-Bus call!"
          shutdown_steam
        fi
        if echo "$line" | grep -q "member=Reboot"; then
          log "Detected 'Reboot' D-Bus call!"
          shutdown_steam
        fi
        if echo "$line" | grep -q "member=Suspend"; then
          log "Detected 'Suspend' D-Bus call!"
          shutdown_steam
        fi
      done &
    '';
    Cmd = ["steam" "-bigpicture"];
    extraPkgs = [dockerTools.caCertificates];
    inherit extraSwayConfig;
  }
