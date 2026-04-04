{
  description = "Container images built with Nix";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    nix2container.url = "github:nlewo/nix2container";
    gadgetmg-pkgs.url = "github:gadgetmg/nix-packages";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} (
      _: {
        systems = ["x86_64-linux"];

        imports = [
          inputs.pkgs-by-name-for-flake-parts.flakeModule
        ];

        perSystem = {
          system,
          pkgs,
          ...
        }: {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              inputs.gadgetmg-pkgs.overlays.default
              (_: _: {inherit (inputs.nixpkgs) lib;})
              (_: _: {inherit (inputs.nix2container.packages.${system}) nix2container;})
            ];
          };
          pkgsDirectory = ./pkgs;
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [just];
          };
        };
      }
    );
}
