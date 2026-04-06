{
  buildEnv,
  coreutils,
  dbus,
  gosu,
  makeDBusConf,
  nix2container,
  pipewire,
  runCommand,
  tini,
  wireplumber,
  writeShellScript,
  imageSource ? "https://github.com/gadgetmg/nix-containers",
}: let
  setup = runCommand "setup" {} ''
    mkdir -p $out/etc/pipewire/pipewire-pulse.conf.d $out/etc/pipewire/pipewire.conf.d $out/run/dbus $out/tmp
    cat > $out/etc/passwd <<EOF
    root:x:0:0::/root:/bin/false
    messagebus:x:1:1::/run/dbus:/bin/false
    docker:x:1000:1000::/tmp:/bin/false
    EOF
    cat > $out/etc/group <<EOF
    root:x:0:
    messagebus:x:1:
    docker:x:1000:
    EOF
    cat > $out/etc/machine-id <<EOF
    00000000000000000000000000000000
    EOF
    cat > $out/etc/pipewire/pipewire-pulse.conf.d/custom.conf <<EOF
    pulse.properties = {
        server.address = [ "unix:pulse-socket" ]
    }
    EOF
  '';
in
  nix2container.buildImage {
    name = "ghcr.io/gadgetmg/pipewire";
    tag = "latest";
    # maxLayers = 120;
    copyToRoot = [
      (buildEnv {
        name = "env";
        paths = [
          setup
          (buildEnv {
            name = "dbus-conf";
            paths = [makeDBusConf];
            extraPrefix = "/etc/dbus-1";
          })
          coreutils
          dbus
          gosu
          pipewire
          tini
          wireplumber
        ];
        ignoreCollisions = true;
      })
    ];
    perms = [
      {
        path = setup;
        regex = "/tmp";
        mode = "0744";
        uid = 1000;
        gid = 1000;
      }
    ];
    config = {
      entrypoint = [
        "tini"
        "--"
        (writeShellScript "entrypoint.sh" ''
          export XDG_RUNTIME_DIR=/tmp
          export DISABLE_RTKIT=y
          mkdir -p /tmp/pulse
          chown docker:docker /tmp/pulse
          dbus-daemon --system --fork
          gosu docker:docker "$@"
        '')
      ];
      Cmd = [
        (writeShellScript "pipewire.sh" ''
          export $(dbus-launch)
          pipewire &
          wireplumber &
          pipewire-pulse &
          wait -n
        '')
      ];
      Labels."org.opencontainers.image.source" = imageSource;
    };
  }
