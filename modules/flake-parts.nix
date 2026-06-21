{inputs, ...}: {
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
      ];
    };
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [just jq];
    };
  };
}
