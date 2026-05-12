{
  description = "UberDDR3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    yosys.url = "git+https://github.com/YosysHQ/yosys?submodules=1";
    openXC7.url = "github:openXC7/toolchain-nix";
    prjxrayDb = {
      url = "github:openXC7/prjxray-db";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, yosys, openXC7, prjxrayDb, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        yosysPkg = yosys.packages.${system}.default;

        openXC7Packages = openXC7.packages.${system};
        openXC7Fasm = openXC7Packages.fasm;
        openXC7Nextpnr = openXC7Packages.nextpnr-xilinx;
        openXC7Prjxray = openXC7Packages.prjxray;
        patchedPrjxrayPython = "${openXC7Prjxray}/usr/share/python3";

        prjxrayPythonDeps = pkgs.python312.withPackages (ps: [
          ps.intervaltree
          ps.progressbar2
          ps.pyjson5
          ps.pyyaml
          ps.simplejson
        ]);
        prjxrayPythonPath =
          "${patchedPrjxrayPython}:${openXC7Fasm}/lib/python3.12/site-packages:${prjxrayPythonDeps}/${pkgs.python312.sitePackages}:${openXC7Prjxray}/usr/share/python3";
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            yosysPkg
            openXC7Nextpnr
            openXC7Fasm
            openXC7Prjxray
            prjxrayPythonDeps
            pkgs.openfpgaloader
            pkgs.openocd
          ];
          shellHook = ''
            export NEXTPNR_XILINX_DIR="${openXC7Nextpnr}/share/nextpnr"
            export NEXTPNR_XILINX_PYTHON_DIR="${openXC7Nextpnr}/share/nextpnr/python"
            export PRJXRAY_DB_DIR="${prjxrayDb}"
            export PRJXRAY_PYTHON_DIR="${openXC7Prjxray}/usr/share/python3"
            export PYTHONPATH="${prjxrayPythonPath}''${PYTHONPATH:+:$PYTHONPATH}"
          '';
        };
      });
}
