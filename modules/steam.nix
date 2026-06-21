{
  inputs,
  withSystem,
  ...
}: {
  flake.nixosConfigurations.steam = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ({pkgs, ...}: {
        imports = [
          inputs.jovian.nixosModules.default
        ];
        system.stateVersion = "26.05";
        boot.isContainer = true;
        nixpkgs = rec {
          hostPlatform.system = "x86_64-linux";
          pkgs = withSystem hostPlatform.system ({pkgs, ...}: pkgs);
        };
        jovian = {
          steamos.useSteamOSConfig = false;
          steam = {
            enable = true;
            gamescope.args = [
              "--backend=wayland"
              "--generate-drm-mode=fixed"
              "--xwayland-count=2"
              "--steam"
              "--ready-fd=\"$socket\""
              "--stats-path=\"$stats\""
            ];
          };
        };
        networking = {
          networkmanager.enable = true;
          wireless.enable = pkgs.lib.mkForce false;
          resolvconf.enable = false;
        };
        hardware.bluetooth.enable = false;
        users.users.retro = {
          linger = true;
          isNormalUser = true;
        };
        programs = {
          bash.enable = true;
          steam = {
            enable = true;
            remotePlay.openFirewall = true;
            localNetworkGameTransfers.openFirewall = true;
          };
        };
        services = {
          journald.console = "/dev/console";
          pipewire.enable = false;
        };
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
              if ((action.id == "org.freedesktop.login1.reboot" ||
                   action.id == "org.freedesktop.login1.power-off")) {
                  return polkit.Result.YES;
              }
          });
        '';
        systemd = {
          services = {
            systemd-udevd.enable = false;
            systemd-oomd.enable = false;
            "user@".serviceConfig.PassEnvironment = "WAYLAND_DISPLAY PULSE_SERVER PULSE_SOURCE PULSE_SINK";
            wolf-fix-permissions = {
              description = "Fix permissions for mounts from Wolf";
              requiredBy = ["basic.target"];
              before = ["basic.target"];
              unitConfig = {
                DefaultDependencies = false;
              };
              serviceConfig = {
                Type = "oneshot";
                PassEnvironment = "WAYLAND_DISPLAY PULSE_SERVER";
                ExecStart = pkgs.writeShellScript "wolf-fix-permissions" ''
                  chown -R retro:users /home/retro
                  chmod -R 777 $(dirname $WAYLAND_DISPLAY) $(dirname $PULSE_SERVER)
                '';
              };
            };
          };
          user.services = {
            gamescope-session.serviceConfig.PassEnvironment = "WAYLAND_DISPLAY PULSE_SERVER PULSE_SOURCE PULSE_SINK";
            start-gamescope-session = {
              wantedBy = ["default.target"];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.gamescope-session}/bin/start-gamescope-session";
              };
            };
          };
        };
      })
    ];
  };

  perSystem = {
    inputs',
    pkgs,
    ...
  }: let
    buildImage = tag:
      inputs'.nix2container.packages.nix2container.buildImage {
        inherit tag;
        name = "ghcr.io/gadgetmg/steam";
        maxLayers = 120;
        copyToRoot = with pkgs; [
          # Wolf execs commands into the container to setup virtual devices.
          # This will occur before systemd can setup /run/current-system and will
          # fail without these packages shimmed into the root of the filesystem
          (buildEnv {
            name = "shim";
            paths = [bash coreutils fakeNss];
            pathsToLink = ["/bin" "/etc"];
          })
        ];
        config = {
          Entrypoint = ["${inputs.self.nixosConfigurations.steam.config.system.build.toplevel}/init"];
          # Wolf will exec into the container to run /bin/bash and
          # /usr/bin/fake-udev, so they need to be in PATH
          Env = ["PATH=/bin:/usr/bin"];
          StopSignal = "SIGRTMIN+3";
          Labels."org.opencontainers.image.source" = "https://github.com/gadgetmg/nix-containers";
        };
      };
    tags = [
      "latest"
      "gamescope"
      "nixos${pkgs.lib.version}"
      "gamescope-nixos${pkgs.lib.version}"
    ];
  in {
    packages = builtins.foldl' (acc: tag:
      acc
      // {
        "steam:${tag}" = buildImage tag;
      }) {}
    tags;
  };
}
