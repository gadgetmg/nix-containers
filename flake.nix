{
  description = "Container images built with Nix";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-input-patcher.url = "github:jfly/flake-input-patcher";
    import-tree.url = "github:vic/import-tree";

    nix2container.url = "github:nlewo/nix2container";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    gadgetmg-pkgs.url = "github:gadgetmg/nix-packages";
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS/development";
    nix-gaming-edge.url = "github:powerofthe69/nix-gaming-edge";
  };

  outputs = unpatchedInputs: let
    inherit (unpatchedInputs.flake-input-patcher.lib.x86_64-linux) patch;
    inputs = patch {
      inherit unpatchedInputs;
      flakePath = ./.;
      patchSpec = {
        jovian.patches = [
          ./patches/jovian.diff
        ];
      };
    };
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree [./modules]);
}
