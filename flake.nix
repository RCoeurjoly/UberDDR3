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

        patchedPrjxrayDb = pkgs.runCommand "prjxray-db-kintex7-lioi3-tbytesrc-oclkm" { } ''
          cp -R --no-preserve=mode,ownership ${prjxrayDb} $out

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.db <<'EOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 30_94 31_83 31_93
EOF

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db <<'EOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 origin:037-iob-pips 30_94 31_83 31_93
EOF
        '';

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
            pkgs.gnumake
            pkgs.openfpgaloader
            pkgs.openocd
            pkgs.pypy3
          ];
          shellHook = ''
            export NEXTPNR_XILINX_DIR="${openXC7Nextpnr}/share/nextpnr"
            export NEXTPNR_XILINX_PYTHON_DIR="${openXC7Nextpnr}/share/nextpnr/python"
            export PRJXRAY_DB_DIR="${patchedPrjxrayDb}"
            export PRJXRAY_PYTHON_DIR="${openXC7Prjxray}/usr/share/python3"
            export PYTHONPATH="${prjxrayPythonPath}''${PYTHONPATH:+:$PYTHONPATH}"
          '';
        };
      });
}
