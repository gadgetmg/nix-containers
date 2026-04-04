{
  bash,
  buildEnv,
  coreutils,
  dockerTools,
  gamescope,
  gcc,
  gosu,
  lib,
  libx11,
  libdrm,
  libglvnd,
  libvdpau-va-gl,
  libxcb,
  libxshmfence,
  mesa,
  nix2container,
  pkgsi686Linux,
  procps,
  runCommand,
  sway,
  vulkan-validation-layers,
  wayland,
  writeShellScript,
  zlib,
  imageSource ? "https://github.com/gadgetmg/nix-containers",
}: {
  name,
  pkg,
  cmd,
  extraPkgs ? [],
  extraSwayConfig ? "",
}: let
  mesa-drivers = [mesa pkgsi686Linux.mesa];
  mesa-glxindirect = runCommand "mesa_glxindirect" {} ''
    mkdir -p $out/lib
    ln -s ${mesa}/lib/libGLX_mesa.so.0 $out/lib/libGLX_indirect.so.0
  '';
  mesa-vulkan-icd = runCommand "mesa_icd" {} ''
    ls ${mesa}/share/vulkan/icd.d/*.json > f
    ls ${pkgsi686Linux.mesa}/share/vulkan/icd.d/*.json >> f
    cat f | xargs | sed "s/ /:/g" > $out
  '';
  libvdpau-drivers = [libvdpau-va-gl pkgsi686Linux.libvdpau-va-gl];
  setup = runCommand "setup" {} ''
    mkdir -p $out/tmp $out/home/retro
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
              bash # used by wolf to run fake-udev commands
              coreutils # used by entrypoint script
              dockerTools.binSh # used by sway for exec commands
              (dockerTools.fakeNss.override {
                extraPasswdLines = ["retro:x:1000:1000:new user:/home/retro:/bin/sh"];
                extraGroupLines = ["retro:x:1000:"];
              })
              gosu # used to drop root
              procps # pkill
            ]
            ++ (lib.optional (compositor == "sway") (sway.override {dbusSupport = false;}))
            ++ (lib.optional (compositor == "gamescope") gamescope)
            ++ extraPkgs;
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
        Entrypoint = [
          (writeShellScript "entrypoint.sh" ''
            # export vars for OpenGL / Vulkan
            export __EGL_VENDOR_LIBRARY_FILENAMES=${mesa}/share/glvnd/egl_vendor.d/50_mesa.json:${pkgsi686Linux.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
            export GBM_BACKENDS_PATH=${lib.makeSearchPathOutput "lib" "lib/gbm" mesa-drivers}
            export LIBGL_DRIVERS_PATH=${lib.makeSearchPathOutput "lib" "lib/dri" mesa-drivers}
            export LIBVA_DRIVERS_PATH=${lib.makeSearchPathOutput "out" "lib/dri" mesa-drivers}
            export VK_LAYER_PATH=${vulkan-validation-layers}/share/vulkan/explicit_layer.d
            export VK_ICD_FILENAMES=''$(cat ${mesa-vulkan-icd})
            export LD_LIBRARY_PATH=${lib.makeLibraryPath (mesa-drivers ++ libvdpau-drivers ++ [libglvnd zlib libdrm libx11 libxcb libxshmfence wayland gcc.cc])}:${lib.makeSearchPathOutput "lib" "lib/vdpau" libvdpau-drivers}:${mesa-glxindirect}/lib

            ${
              lib.optionalString (compositor == "sway") ''

                # configure sway
                mkdir -p /home/retro/.config/sway
                cat <<EOF >/home/retro/.config/sway/config
                set \''$mod Mod4
                output * resolution ''${GAMESCOPE_WIDTH}x''${GAMESCOPE_HEIGHT} position 0,0
                bindsym \''$mod+f fullscreen
                ${extraSwayConfig}
                exec ${cmd} && pkill sway
                EOF
              ''
            }
            # set permissions
            chown -R retro:retro /home/retro ''${XDG_RUNTIME_DIR}

            ${lib.optionalString (compositor == "sway") ''gosu retro sway'' + lib.optionalString (compositor == "gamescope") ''gosu retro gamescope --steam ''${GAMESCOPE_MODE} -W ''${GAMESCOPE_WIDTH} -H ''${GAMESCOPE_HEIGHT} ''$1 -- ${cmd}''}
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
