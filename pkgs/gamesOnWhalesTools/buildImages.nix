{
  bash,
  buildEnv,
  coreutils,
  dbus,
  dockerTools,
  foot,
  gamescope,
  gnugrep,
  gosu,
  lib,
  libvdpau-va-gl,
  makeDBusConf,
  mesa,
  networkmanager,
  nix2container,
  pkgsi686Linux,
  procps,
  runCommand,
  sway,
  tini,
  wmenu,
  writeShellScript,
  imageSource ? "https://github.com/gadgetmg/nix-containers",
}: {
  name,
  pkg,
  Cmd,
  helperScript ? "",
  extraPkgs ? [],
  extraSwayConfig ? "",
}: let
  opengl-driver = buildEnv {
    name = "opengl-driver";
    paths = [
      mesa
      libvdpau-va-gl
      (
        runCommand "mesa_glxindirect" {} ''
          mkdir -p $out/lib
          ln -s ${mesa}/lib/libGLX_mesa.so.0 $out/lib/libGLX_indirect.so.0
        ''
      )
    ];
  };
  opengl-driver-32 = buildEnv {
    name = "opengl-driver-32";
    paths = [
      pkgsi686Linux.mesa
      pkgsi686Linux.libvdpau-va-gl
      (
        runCommand "mesa_glxindirect" {} ''
          mkdir -p $out/lib
          ln -s ${pkgsi686Linux.mesa}/lib/libGLX_mesa.so.0 $out/lib/libGLX_indirect.so.0
        ''
      )
    ];
  };
  setup = runCommand "setup" {} ''
    mkdir -p $out/run/dbus $out/tmp $out/home/retro
    ln -s ${opengl-driver} $out/run/opengl-driver
    ln -s ${opengl-driver-32} $out/run/opengl-driver-32
  '';
  buildVariant = pkg: compositor: tag:
    nix2container.buildImage {
      inherit name;
      inherit tag;
      maxLayers = 120;
      copyToRoot = [
        (buildEnv {
          name = "env";
          paths =
            [
              setup
              (buildEnv {
                name = "dbus-conf";
                paths = [makeDBusConf];
                extraPrefix = "/etc/dbus-1";
              })
              bash # used by wolf to run fake-udev commands
              coreutils # used by entrypoint script
              gnugrep
              dbus
              networkmanager
              dockerTools.binSh # used by sway for exec commands
              (dockerTools.fakeNss.override {
                extraPasswdLines = [
                  "retro:x:1000:1000::/home/retro:/bin/bash"
                  "messagebus:x:1:1::/run/dbus:/bin/false"
                ];
                extraGroupLines = [
                  "retro:x:1000:"
                  "messagebus:x:1:"
                ];
              })
              gosu # used to drop root
              procps # pkill
              tini
              gamescope
              pkg
            ]
            ++ lib.optionals (compositor == "sway") [sway foot wmenu]
            ++ extraPkgs;
          ignoreCollisions = true;
        })
      ];
      perms = [
        {
          path = setup;
          regex = "/tmp";
          mode = "1777";
        }
        {
          path = setup;
          regex = "/home/retro";
          mode = "0744";
          uname = "retro";
          uid = 1000;
          gname = "retro";
          gid = 1000;
        }
      ];
      config = {
        inherit Cmd;
        Entrypoint = [
          "tini"
          "--"
          (writeShellScript "entrypoint.sh" ''
            # generate /etc/machine-id
            (tr -dc 0-9a-f < /dev/urandom | head -c 32; echo) > /etc/machine-id

            ${
              lib.optionalString (compositor == "sway") ''

                # configure sway
                mkdir -p /home/retro/.config/sway
                cat <<EOF >/home/retro/.config/sway/config
                include /etc/sway/config
                output * resolution ''${GAMESCOPE_WIDTH}x''${GAMESCOPE_HEIGHT} position 0,0
                ${extraSwayConfig}
                exec $@ && pkill sway
                EOF
              ''
            }
            mkdir -p ''${XDG_RUNTIME_DIR}
            # set permissions
            chown -R retro:retro /home/retro ''${XDG_RUNTIME_DIR}
            # start dbus
            dbus-daemon --system --fork 2>&1
            # start networkmanager
            NetworkManager
            # start user dbus session
            export $(gosu retro dbus-launch)
            # start helper script
            ${helperScript}
            # launch compositor
            gosu retro ${lib.optionalString (compositor == "sway") ''sway'' + lib.optionalString (compositor == "gamescope") ''gamescope -e --backend wayland ''${GAMESCOPE_MODE} -W ''${GAMESCOPE_WIDTH} -H ''${GAMESCOPE_HEIGHT} ''$1 -- $@''}
          '')
        ];
        Env = lib.flatten ([
            "XDG_RUNTIME_DIR=/run/user/wolf"
            "WLR_BACKENDS=wayland"
            "GAMESCOPE_WIDTH=1920"
            "GAMESCOPE_HEIGHT=1080"
          ]
          ++ (lib.optional (compositor == "gamescope") [
            "GAMESCOPE_MODE=-f"
          ]));
        Labels."org.opencontainers.image.source" = imageSource;
      };
    };
in {
  "${pkg.version}-sway-nixos${lib.version}" =
    buildVariant pkg "sway" "${pkg.version}-sway-nixos${lib.version}";

  "${pkg.version}-nixos${lib.version}" =
    buildVariant pkg "sway" "${pkg.version}-nixos${lib.version}";

  "${pkg.version}" =
    buildVariant pkg "sway" "${pkg.version}";

  "sway" =
    buildVariant pkg "sway" "sway";

  "latest" =
    buildVariant pkg "sway" "latest";

  "${pkg.version}-gamescope-nixos${lib.version}" =
    buildVariant pkg "gamescope" "${pkg.version}-gamescope-nixos${lib.version}";

  "gamescope" =
    buildVariant pkg "gamescope" "gamescope";
}
