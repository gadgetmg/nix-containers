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
        inherit (pkgs) lib callPackage;
        buildVariants = imageName: mainPkg: builder: {
          "${imageName}:${mainPkg.version}-sway-nixos${lib.version}" = callPackage builder {};
          "${imageName}:${mainPkg.version}-nixos${lib.version}" = callPackage builder {};
          "${imageName}:${mainPkg.version}" = callPackage builder {};
          "${imageName}:sway" = callPackage builder {};
          "${imageName}:latest" = callPackage builder {};
          "${imageName}:${mainPkg.version}-gamescope-nixos${lib.version}" = callPackage builder {compositor = "gamescope";};
          "${imageName}:gamescope" = callPackage builder {compositor = "gamescope";};
        };
      in
        acc
        // (buildVariants "steam" pkgs.steam ./packages/steam)
        // (buildVariants "retroarch" pkgs.retroarch-bare ./packages/retroarch)
    ) {} [unstable stable];

    devShells.x86_64-linux.default = let
      pkgs = stable.legacyPackages.x86_64-linux;
    in
      pkgs.mkShell {
        buildInputs = with pkgs; [
          just
          skopeo
        ];
      };
  };
}
