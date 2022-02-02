{
  description = "Flake to manage Kelvin SDK workspace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    mach-nix = {
      url = "github:DavHau/mach-nix/3.5.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, mach-nix }:
    let
      python = "python39";
      pypiDataRev = "master";
      pypiDataSha256 = "1pslaz427anqiyiwpq406f8wf0i0clvyjpx8wzairx219glq5kzb";
      devShell = pkgs:
        pkgs.mkShell {
          buildInputs = [
            (pkgs.${python}.withPackages
              (ps: with ps; [
                black
                build
                flake8
                ipython
                isort
                mypy
                pip
                safety
                setuptools-scm
                tox
              ]))
          ];
        };
      extra = ''
        pdbpp
        kelvin-sdk==7.7.0
      '';
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
        with builtins;
        let
          pkgs = import nixpkgs { inherit system; };
          mach-nix-wrapper = import mach-nix {
            inherit pkgs python pypiDataRev pypiDataSha256;
          };
          pythonShell = mach-nix-wrapper.mkPythonShell {
            requirements = (readFile ./requirements.txt) + extra;
          };
          mergeEnvs = envs:
            pkgs.mkShell (
              foldl'
                (x: y: {
                  buildInputs = x.buildInputs ++ y.buildInputs;
                  nativeBuildInputs = x.nativeBuildInputs ++ y.nativeBuildInputs;
                })
                (pkgs.mkShell { })
                envs);
        in
        {
          devShell = mergeEnvs [ (devShell pkgs) pythonShell ];
        }
    );
}
