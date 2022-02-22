{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
  let
    # python39 doesn't seem to work because of the the setuptools not understanding environment
    # marker like 'typing-extensions>=3.10.0.0; python_version < "3.10"' 
    pythonDrvName = "python310";
  in {
      # Nixpkgs overlay providing the application
      overlay = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: prev: {
          poetry = prev.poetry.override { python = final.${pythonDrvName}; };
          # The application
          myapp = prev.poetry2nix.mkPoetryApplication {
            projectDir = ./.;
            python = final.${pythonDrvName};
          };
        })
      ];
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
      in
      {
        apps = {
          myapp = pkgs.myapp;
        };

        defaultApp = pkgs.myapp;

        devShell = (pkgs.poetry2nix.mkPoetryEnv {
          projectDir = ./.;
          editablePackageSources = {
            myapp = ./thehodl;
          };
          python = pkgs.${pythonDrvName};
        }).env;
      }));
}
