{
  description = "UberDDR3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    yosys.url = "git+https://github.com/YosysHQ/yosys?submodules=1";
    openXC7.url = "github:openXC7/toolchain-nix";
    nextpnrXilinxPhaser = {
      url = "git+https://github.com/RCoeurjoly/nextpnr-xilinx?ref=stable-backports&submodules=1";
      flake = false;
    };
    prjxrayDb = {
      url = "github:openXC7/prjxray-db";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, yosys, openXC7, nextpnrXilinxPhaser, prjxrayDb, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        yosysPkg = yosys.packages.${system}.default;

        openXC7Packages = openXC7.packages.${system};
        openXC7Fasm = openXC7Packages.fasm;
        openXC7Nextpnr = openXC7Packages.nextpnr-xilinx.overrideAttrs (old: {
          src = nextpnrXilinxPhaser;
          version = "phaser-";
        });
        openXC7Prjxray = openXC7Packages.prjxray;
        patchedPrjxrayPython = "${openXC7Prjxray}/usr/share/python3";

        patchedPrjxrayDb = pkgs.runCommand "prjxray-db-kintex7-lioi3-tbytesrc-oclkm-phaser-overlay" { } ''
          mkdir -p $out
          ${pkgs.python3}/bin/python3 ${./scripts/task6/build_phaser_prjxray_db_overlay.py} \
            --source-db ${prjxrayDb}/kintex7 \
            --out-db $out/kintex7 \
            --clean

          for db_file in \
            $out/kintex7/segbits_lioi3_tbytesrc.db \
            $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db
          do
            if [ -L "$db_file" ]; then
              cp --remove-destination "$(readlink -f "$db_file")" "$db_file"
            fi
            chmod u+w "$db_file"
          done

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.db <<'EOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 30_94 31_83 31_93
EOF

          cat >> $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db <<'EOF'
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 origin:037-iob-pips 30_94 31_83 31_93
EOF
        '';

        fickling = pkgs.python312Packages.buildPythonPackage rec {
          pname = "fickling";
          version = "0.1.11";
          format = "wheel";

          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/ed/3b/45b8233feb53dd9da16208b039507604844a07c8b5bb3c5a4e39c520f32d/fickling-0.1.11-py3-none-any.whl";
            hash = "sha256-Gey3kdeB1HXoTtlR3CxKDIUhCOI3QW1RerCo3XcdQJg=";
          };

          doCheck = false;
        };

        graphtage = pkgs.python312Packages.graphtage.overridePythonAttrs (old: {
          propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ fickling ];
        });

        graphtagePythonEnv = pkgs.python312.withPackages (ps: [ graphtage ]);

        prjxrayPythonDeps = pkgs.python312.withPackages (ps: [
          ps.intervaltree
          ps.packaging
          ps.progressbar2
          ps.pyjson5
          ps.pyyaml
          ps.simplejson
        ]);
        prjxrayPythonPath =
          "${patchedPrjxrayPython}:${openXC7Fasm}/lib/python3.12/site-packages:${prjxrayPythonDeps}/${pkgs.python312.sitePackages}:${openXC7Prjxray}/usr/share/python3";

        mkSource = let
          sourceRoot = ./.;
          keep = [
            "example_demo/ypcb_00338_1p1"
            "rtl"
            "fpga/rtl"
            "scripts/task6"
            "artifacts/task6/baselines/uberddr3-rowstream-loader-v40-physical-stability"
          ];
          shouldKeep = rel:
            builtins.any (root:
              rel == root
              || pkgs.lib.hasPrefix (root + "/") rel
              || pkgs.lib.hasPrefix (rel + "/") (root + "/")
            ) keep;
        in
          pkgs.lib.cleanSourceWith {
            src = sourceRoot;
            filter = path: type:
              let
                rel = pkgs.lib.removePrefix (toString sourceRoot + "/") (toString path);
              in
                if rel == "" then true else shouldKeep rel;
          };

        mkYpcbRowstreamBitstream = {
          seed,
          freq,
          synthXilinxFlags ? "-flatten -arch xc7",
          makeTarget ? "rowstream-v40-locked",
          outputStem ? "ypcb_00338_1p1_uberddr3_rowstream_loader",
          artifactPrefix ? "rowstream",
          pnrExtraArgs ? "",
        }:
          pkgs.stdenvNoCC.mkDerivation {
            pname = "ypcb-${artifactPrefix}";
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
              make ${makeTarget} \
                SYNTH_XILINX_FLAGS="${synthXilinxFlags}" \
                PNR_ARGS="--seed ${toString seed} --freq ${toString freq} ${pnrExtraArgs}" \
                PNR_DEBUG="--write ../../artifacts/manual-seed/seed${toString seed}/nextpnr-routed.json"
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp ${outputStem}_openxc7.bit $out/${artifactPrefix}_seed${toString seed}_freq${toString freq}.bit
              cp ../../artifacts/manual-seed/seed${toString seed}/nextpnr-routed.json $out/nextpnr-routed.seed${toString seed}_freq${toString freq}.json
              cp ${outputStem}_openxc7.bit $out/${outputStem}_openxc7.bit
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
          phaser-nextpnr-xilinx = openXC7Nextpnr;
          default = mkYpcbRowstreamBitstream {
            seed = 3;
            freq = 25;
          };
          ypcb-rowstream-seed-3-freq-25-timing-allow-fail = mkYpcbRowstreamBitstream {
            seed = 3;
            freq = 25;
            artifactPrefix = "rowstream-timing-allow-fail";
            pnrExtraArgs = "--timing-allow-fail";
          };
          ypcb-rowstream-fullbeat-seed-3-freq-25 = mkYpcbRowstreamBitstream {
            seed = 3;
            freq = 25;
            makeTarget = "rowstream-fullbeat-v40-locked";
            outputStem = "ypcb_00338_1p1_uberddr3_rowstream_fullbeat";
            artifactPrefix = "rowstream-fullbeat";
          };
          ypcb-rowstream-fullbeat-seed-3-freq-25-timing-allow-fail = mkYpcbRowstreamBitstream {
            seed = 3;
            freq = 25;
            makeTarget = "rowstream-fullbeat-v40-locked";
            outputStem = "ypcb_00338_1p1_uberddr3_rowstream_fullbeat";
            artifactPrefix = "rowstream-fullbeat-timing-allow-fail";
            pnrExtraArgs = "--timing-allow-fail";
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
            pkgs.verilog
            pkgs.openfpgaloader
            pkgs.openocd
            pkgs.pypy3
            graphtagePythonEnv
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
