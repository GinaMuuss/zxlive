{
  description = "A basic flake using pyproject.toml project metadata";

  inputs.pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
  inputs.pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { nixpkgs, pyproject-nix, flake-utils, ... }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          system = system;
        };
        lib = nixpkgs.lib;
 
        # Loads pyproject.toml into a high-level project representation
        project = pyproject-nix.lib.project.loadPyproject {
          projectRoot = ./.;
        };

        # PyProject.nix ignores the dependency sources, so we have to manually fix that we need the dev version of pyzx
        python =
          let
            packageOverrides = self: super: {
              pyzx = super.pyzx.overridePythonAttrs (old: rec {
                version = "dev";
                src = pkgs.fetchFromGitHub {
                  owner = "zxcalc";
                  repo = "pyzx";
                  rev = "master";
                  hash = "sha256-YAqkNhdq7kPObTXXWCYZDtiBKoz7+op1oW/NuleP6+c=";
                };
              });
            };
          in
          pkgs.python3.override {
            inherit packageOverrides;
            self = python;
          };
      in
      {
        # Create a development shell containing dependencies from `pyproject.toml`
        devShells.default =
          let
            arg = project.renderers.withPackages { inherit python; };
            pythonEnv = python.withPackages arg;

          in
          pkgs.mkShell { packages = [ pythonEnv ]; };

        # Build our package using `buildPythonPackage`
        packages.default =
          let
            attrs = project.renderers.buildPythonPackage { inherit python; };
          in
          python.pkgs.buildPythonPackage (attrs);
      }
    ));
}
