{
  description = "Container images built with Nix";

  inputs = {
    stable.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    stable,
    unstable,
  }: {
    packages.x86_64-linux = builtins.foldl' (
      acc: channel: let
        pkgs = import channel {
          system = "x86_64-linux";
          config.allowUnfree = true;
          # uses flake-level lib overlaying version information
          overlays = [(_: _: {inherit (channel) lib;})];
        };
        inherit (pkgs) lib callPackage steam;
      in
        acc
        // {
          "steam:${steam.version}-sway-nixos${lib.version}" = callPackage ./packages/steam {};
          "steam:${steam.version}-nixos${lib.version}" = callPackage ./packages/steam {};
          "steam:${steam.version}" = callPackage ./packages/steam {};
          "steam:sway" = callPackage ./packages/steam {};
          "steam:latest" = callPackage ./packages/steam {};

          "steam:${steam.version}-gamescope-nixos${lib.version}" = callPackage ./packages/steam {compositor = "gamescope";};
          "steam:gamescope" = callPackage ./packages/steam {compositor = "gamescope";};
        }
    ) {} [unstable stable];

    devShells.x86_64-linux.default = let
      pkgs = stable.legacyPackages.x86_64-linux;
      inherit (pkgs) mkShell just skopeo;
    in
      mkShell {
        buildInputs = [
          just
          skopeo
        ];
      };
  };
}
