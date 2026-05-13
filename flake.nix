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

        mkSource = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            let
              name = baseNameOf path;
            in
              name != "result";
        };

        mkYpcbRowstreamBitstream = {
          seed,
          freq,
          synthXilinxFlags ? "-flatten -arch xc7",
        }:
          pkgs.stdenvNoCC.mkDerivation {
            pname = "ypcb-rowstream-loader";
            version = "seed-${toString seed}-freq-${toString freq}";
            src = mkSource;

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
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.libftdi1 ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

              cd example_demo/ypcb_00338_1p1
              mkdir -p ../../artifacts/manual-seed/seed${toString seed}

              make clean
              make rowstream-v40-locked \
                SYNTH_XILINX_FLAGS="${synthXilinxFlags}" \
                PNR_ARGS="--seed ${toString seed} --freq ${toString freq}" \
                PNR_DEBUG="--write ../../artifacts/manual-seed/seed${toString seed}/nextpnr-routed.json"
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp ypcb_00338_1p1_uberddr3_rowstream_loader_openxc7.bit $out/rowstream_seed${toString seed}_freq${toString freq}.bit
              cp ../../artifacts/manual-seed/seed${toString seed}/nextpnr-routed.json $out/nextpnr-routed.seed${toString seed}_freq${toString freq}.json
              cp ypcb_00338_1p1_uberddr3_rowstream_loader_openxc7.bit $out/ypcb_00338_1p1_uberddr3_rowstream_loader_openxc7.bit
              runHook postInstall
            '';
          };

        ypcbSeedPlans = builtins.listToAttrs (
          map (seed: {
            name = "ypcb-rowstream-seed-${toString seed}-freq-${toString 25}";
            value = mkYpcbRowstreamBitstream {
              inherit seed;
              freq = 25;
            };
          })
          [0 3 16 40 44]
        );
      in {
        packages = ypcbSeedPlans // {
          default = mkYpcbRowstreamBitstream {
            seed = 3;
            freq = 25;
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            yosysPkg
            openXC7Nextpnr
            openXC7Fasm
            openXC7Prjxray
            prjxrayPythonDeps
            pkgs.libftdi1
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
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.libftdi1 ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          '';
        };
      });
}
