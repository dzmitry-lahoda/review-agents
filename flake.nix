{
  description = "Review agents development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    codegraph.url = "github:dzmitry-lahoda-forks/codegraph/codex/add-nix-flake";
  };

  outputs = { nixpkgs, nixpkgs-unstable, codegraph, ... }:
    let
      supportedSystems = [
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          unstablePkgs = import nixpkgs-unstable { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              codegraph.packages.${system}.default
              pkgs.postgresql
              pkgs.python3
              pkgs.uv
              unstablePkgs.squawk
            ];
          };
        });
    };
}
