{
  lib,
  bash,
  coreutils,
  dockerTools,
  gamescope,
  gcc,
  gosu,
  libdrm,
  libglvnd,
  libvdpau-va-gl,
  mesa,
  pkgsi686Linux,
  runCommand,
  shadow,
  steam,
  sway,
  vulkan-validation-layers,
  wayland,
  writeShellScript,
  xorg,
  zlib,
  imageSource ? "https://github.com/gadgetmg/nix-containers",
  compositor ? "sway",
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
  entrypoint = writeShellScript "entrypoint.sh" ''
    # export vars for OpenGL / Vulkan
    export __EGL_VENDOR_LIBRARY_FILENAMES=${mesa}/share/glvnd/egl_vendor.d/50_mesa.json:${pkgsi686Linux.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
    export GBM_BACKENDS_PATH=${lib.makeSearchPathOutput "lib" "lib/gbm" mesa-drivers}
    export LIBGL_DRIVERS_PATH=${lib.makeSearchPathOutput "lib" "lib/dri" mesa-drivers}
    export LIBVA_DRIVERS_PATH=${lib.makeSearchPathOutput "out" "lib/dri" mesa-drivers}
    export VK_LAYER_PATH=${vulkan-validation-layers}/share/vulkan/explicit_layer.d
    export VK_ICD_FILENAMES=''$(cat ${mesa-vulkan-icd})
    export LD_LIBRARY_PATH=${lib.makeLibraryPath (mesa-drivers ++ libvdpau-drivers ++ [libglvnd zlib libdrm xorg.libX11 xorg.libxcb xorg.libxshmfence wayland gcc.cc])}:${lib.makeSearchPathOutput "lib" "lib/vdpau" libvdpau-drivers}:${mesa-glxindirect}/lib

    # add user and directories
    groupadd -g ''${GID} ''${UNAME}
    useradd -g ''${UNAME} -u ''${UID} ''${UNAME}
    mkdir -p ''${HOME} ''${XDG_RUNTIME_DIR}
    ${
      lib.optionalString (compositor == "sway") ''

        # configure sway
        mkdir -p ''${HOME}/.config/sway
        cat <<EOF >''${HOME}/.config/sway/config
          set \''$mod Mod4
          output * resolution ''${GAMESCOPE_WIDTH}x''${GAMESCOPE_HEIGHT} position 0,0
          bindsym \''$mod+f fullscreen
          for_window [instance="steamwebhelper"] border none
          for_window [instance="steam_app_.*"] fullscreen enable
          for_window [app_id="steam_app_.*"] fullscreen enable
          exec steam -bigpicture && kill 1
        EOF
      ''
    }
    # set permissions
    chown -R ''${UNAME}:''${UNAME} ''${HOME} ''${XDG_RUNTIME_DIR}

    ${lib.optionalString (compositor == "sway") ''gosu ''${UNAME} sway ''$1'' + lib.optionalString (compositor == "gamescope") ''gosu ''${UNAME} gamescope --steam ''${GAMESCOPE_MODE} -W ''${GAMESCOPE_WIDTH} -H ''${GAMESCOPE_HEIGHT} ''$1 -- steam -bigpicture''}
  '';
in
  assert builtins.elem compositor ["sway" "gamescope"];
    dockerTools.buildLayeredImage {
      name = "steam";
      created = "now";
      contents =
        [
          bash # used by wolf to run fake-udev commands
          coreutils # used by entrypoint script
          dockerTools.binSh # used by sway for exec commands
          dockerTools.caCertificates # used by steam
          gosu # used to drop root
          shadow # used to create unprivileged user
          steam
        ]
        ++ (lib.optional (compositor == "sway") (sway.override {dbusSupport = false;}))
        ++ (lib.optional (compositor == "gamescope") gamescope);
      enableFakechroot = true;
      fakeRootCommands = ''
        ${dockerTools.shadowSetup}
        mkdir -p /home /root /tmp /run
        chmod 1777 /tmp
      '';
      config = {
        Entrypoint = [entrypoint];
        Env = lib.flatten ([
            "UNAME=retro"
            "UID=1000"
            "GID=1000"
            "HOME=/home/retro"
            "XDG_RUNTIME_DIR=/run/user/wolf"
            "WLR_BACKENDS=wayland"
          ]
          ++ (lib.optional (compositor == "gamescope") [
            "GAMESCOPE_MODE=-f"
            "GAMESCOPE_WIDTH=1920"
            "GAMESCOPE_HEIGHT=1080"
          ]));
        Labels."org.opencontainers.image.source" = imageSource;
      };
    }
