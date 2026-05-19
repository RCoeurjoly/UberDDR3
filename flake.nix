{
  description = "Minimal YPCB UberDDR3 OpenXC7 timing reproducer";

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

        prjxrayPythonDeps = pkgs.python312.withPackages (ps: [
          ps.intervaltree
          ps.packaging
          ps.progressbar2
          ps.pyjson5
          ps.pyyaml
          ps.simplejson
        ]);

        prjxrayPythonPath =
          "${openXC7Prjxray}/usr/share/python3:${openXC7Fasm}/lib/python3.12/site-packages:${prjxrayPythonDeps}/${pkgs.python312.sitePackages}";

        patchedPrjxrayDb = pkgs.runCommand "prjxray-db-kintex7-lioi3-tbytesrc-oclkm" { } ''
          cp -R --no-preserve=mode,ownership ${prjxrayDb} $out

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.db <<'DBEOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 30_94 31_83 31_93
DBEOF

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db <<'DBEOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 origin:037-iob-pips 30_94 31_83 31_93
DBEOF
        '';

        source = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            let
              rel = pkgs.lib.removePrefix (toString ./. + "/") (toString path);
            in
              rel == "" ||
              rel == "example_demo" ||
              rel == "example_demo/ypcb_00338_1p1" ||
              pkgs.lib.hasPrefix "example_demo/ypcb_00338_1p1/" rel ||
              rel == "rtl" ||
              pkgs.lib.hasPrefix "rtl/" rel ||
              false;
        };

        ypcbOpenxc7333Bitstream = pkgs.stdenvNoCC.mkDerivation {
          pname = "ypcb-uberddr3-openxc7-333";
          version = "seed-3";
          src = source;

          buildInputs = [
            yosysPkg
            openXC7Nextpnr
            openXC7Fasm
            openXC7Prjxray
            prjxrayPythonDeps
            pkgs.gnumake
            pkgs.pypy3
          ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild

            export NEXTPNR_XILINX_DIR="${openXC7Nextpnr}/share/nextpnr"
            export NEXTPNR_XILINX_PYTHON_DIR="${openXC7Nextpnr}/share/nextpnr/python"
            export PRJXRAY_DB_DIR="${patchedPrjxrayDb}"
            export PRJXRAY_PYTHON_DIR="${openXC7Prjxray}/usr/share/python3"
            export PYTHONPATH="${prjxrayPythonPath}''${PYTHONPATH:+:$PYTHONPATH}"

            cd example_demo/ypcb_00338_1p1
            make clean
            make openxc7 \
              YPCB_UBERDDR3_CLOCK_PROFILE=openxc7-333 \
              CHIPDB=. \
              PNR_ARGS="--seed 3 --timing-allow-fail" \
              PNR_DEBUG="--write nextpnr-routed.json"

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp ypcb_00338_1p1_ddr3_openxc7.bit $out/ypcb-uberddr3-openxc7-333-seed3.bit
            cp ypcb_00338_1p1_ddr3.fasm $out/ypcb-uberddr3-openxc7-333-seed3.fasm
            cp ypcb_00338_1p1_ddr3.frames $out/ypcb-uberddr3-openxc7-333-seed3.frames
            cp nextpnr-routed.json $out/nextpnr-routed.json

            runHook postInstall
          '';
        };
      in {
        packages = {
          default = ypcbOpenxc7333Bitstream;
          ypcb-openxc7-333-bitstream = ypcbOpenxc7333Bitstream;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            yosysPkg
            openXC7Nextpnr
            openXC7Fasm
            openXC7Prjxray
            prjxrayPythonDeps
            pkgs.gnumake
            pkgs.pypy3
            pkgs.openocd
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
