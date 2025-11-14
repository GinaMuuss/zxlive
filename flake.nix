{
  description = "A basic flake using pyproject.toml project metadata";

  inputs.pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
  inputs.pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  outputs =
    {
      nixpkgs,
      pyproject-nix,
      flake-utils,
      ...
    }:
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
                  owner = "GinaMuuss";
                  repo = "pyzx";
                  rev = "master";
                  hash = "sha256-82rnQFNG9EoqTHxOFzNUanU61zW43CXq/LiPHJA6uWA=";
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
          pkgs.mkShell rec {
            name = "impurePythonEnv";
            venvDir = "./.venv";
            buildInputs = [
              # A Python interpreter including the 'venv' module is required to bootstrap
              # the environment.
              pkgs.python3Packages.python

              # This executes some shell code to initialize a venv in $venvDir before
              # dropping into the shell
              pkgs.python3Packages.venvShellHook

              # Those are dependencies that we would like to use from nixpkgs, which will
              # add them to PYTHONPATH and thus make them accessible from within the venv.
              pkgs.python3Packages.pyside6
              pythonEnv
            ];

            # Run this command, only after creating the virtual environment
            postVenvCreation = ''
              unset SOURCE_DATE_EPOCH
              pip install .
            '';

            # Now we can execute any commands within the virtual environment.
            # This is optional and can be left out to run pip manually.
            postShellHook = ''
              # allow pip to install wheels
              unset SOURCE_DATE_EPOCH
            '';
            #           export PYTHONPATH=${venvDir}/lib/python3.12/site-packages:$PYTHONPATH
          };

        # Build our package using `buildPythonPackage`
        packages.default =
          let
            attrs = project.renderers.buildPythonPackage { inherit python; };
          in
          python.pkgs.buildPythonPackage (attrs);
      }
    ));
}
