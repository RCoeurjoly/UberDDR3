{
  description = "UberDDR3 OpenXC7 development shell and YPCB DDR3 reference builds";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    toolchain-nix.url = "github:openXC7/toolchain-nix";
    nixpkgs.follows = "toolchain-nix/nixpkgs";
  };

  outputs = { self, flake-utils, nixpkgs, toolchain-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        openXc7Shell = toolchain-nix.devShell.${system};
        openXc7Packages = toolchain-nix.packages.${system};
        nextpnrXilinx = openXc7Packages.nextpnr-xilinx.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/nextpnr-xilinx-heap-fixed-constrained-children.patch
          ];
        });
        prjxray = openXc7Packages.prjxray;
        fasm = openXc7Packages.fasm;
        sdfToolkitClick = pkgs.python311Packages.buildPythonPackage rec {
          pname = "click";
          version = "8.2.1";
          format = "wheel";
          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/py3/c/click/click-${version}-py3-none-any.whl";
            hash = "sha256-YaMmW5FOhQuFMX0LMQnH+M01pnD5Y4ZgBdbvHVF1oSs=";
          };
          doCheck = false;
          pythonImportsCheck = [ "click" ];
        };
        sdfToolkitRich = pkgs.python311Packages.buildPythonPackage rec {
          pname = "rich";
          version = "14.3.3";
          format = "wheel";
          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/py3/r/rich/rich-${version}-py3-none-any.whl";
            hash = "sha256-eTQxwfhhmvp9O1KyzeyFlWK5UOoNS2tQU5dhLbjVNi0=";
          };
          propagatedBuildInputs = with pkgs.python311Packages; [ markdown-it-py pygments ];
          doCheck = false;
          pythonImportsCheck = [ "rich" ];
        };
        sdfToolkitAnnotatedDoc = pkgs.python311Packages.buildPythonPackage rec {
          pname = "annotated-doc";
          version = "0.0.4";
          format = "wheel";
          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/py3/a/annotated-doc/annotated_doc-${version}-py3-none-any.whl";
            hash = "sha256-VxrB3GmRxFCyWpwthKNwXirnpTRntdERwk+ouqu+0yA=";
          };
          doCheck = false;
          pythonImportsCheck = [ "annotated_doc" ];
        };
        sdfToolkitTyper = pkgs.python311Packages.buildPythonPackage rec {
          pname = "typer";
          version = "0.24.1";
          format = "wheel";
          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/py3/t/typer/typer-${version}-py3-none-any.whl";
            hash = "sha256-ESwfDOV4v7TKuf/avGjwMUFuvMIWU2YRuiHwTpqoTJ4=";
          };
          propagatedBuildInputs = with pkgs.python311Packages; [
            shellingham
          ] ++ [ sdfToolkitAnnotatedDoc sdfToolkitClick sdfToolkitRich ];
          doCheck = false;
          pythonImportsCheck = [ "typer" ];
        };
        sdfToolkit = pkgs.python311Packages.buildPythonPackage rec {
          pname = "sdf-toolkit";
          version = "0.1.1";
          format = "pyproject";
          src = pkgs.fetchPypi {
            pname = "sdf_toolkit";
            inherit version;
            hash = "sha256-s5D6TitfRk+7Q6VRiAhFG+D0zQNkqx+gnMURxrQKG1c=";
          };
          postPatch = ''
            substituteInPlace src/sdf_toolkit/parser/sdf.lark \
              --replace-fail 'STRING: /[a-zA-Z0-9_\/.\[\]\\]+/' 'STRING: /[a-zA-Z0-9_\/.\[\]\\\$:\-]+/'
          '';
          nativeBuildInputs = with pkgs.python311Packages; [
            hatchling
            hatch-vcs
          ];
          propagatedBuildInputs = with pkgs.python311Packages; [
            jinja2
            lark
            networkx
            sdfToolkitRich
            sdfToolkitTyper
          ];
          doCheck = false;
          pythonImportsCheck = [ "sdf_toolkit" ];
          meta = {
            description = "Python library and CLI toolkit for Standard Delay Format timing files";
            homepage = "https://github.com/KelvinChung2000/sdf-toolkit";
            license = pkgs.lib.licenses.asl20;
            mainProgram = "sdf-toolkit";
          };
        };
        originalPrjxrayDb = "${nextpnrXilinx}/share/nextpnr/external/prjxray-db";
        patchedPrjxrayDb = pkgs.runCommand "prjxray-db-kintex7-lioi3-tbytesrc-oclkm-overlay" { } ''
          mkdir -p $out
          cp -a ${originalPrjxrayDb}/kintex7 $out/kintex7

          for db_file in \
            $out/kintex7/segbits_lioi3_tbytesrc.db \
            $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db
          do
            chmod u+w "$db_file"
          done

          if ! grep -q "^LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 " \
            $out/kintex7/segbits_lioi3_tbytesrc.db
          then
            cat >> $out/kintex7/segbits_lioi3_tbytesrc.db <<DBEOF
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 30_94 31_83 31_93
DBEOF
          fi

          if ! grep -q "^LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 " \
            $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db
          then
            cat >> $out/kintex7/segbits_lioi3_tbytesrc.origin_info.db <<DBEOF
LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1 origin:037-iob-pips 30_94 31_83 31_93
DBEOF
          fi
        '';

        ypcb = rec {
          project = "ypcb_00338_1p1_ddr3";
          top = project;
          boardDir = "example_demo/ypcb_00338_1p1";
          part = "xc7k480tffg1156-2";
          dbpart = "xc7k480tffg1156";
          family = "kintex7";
          freqMHz = "83.333";
          sources = [
            "${boardDir}/${project}.v"
            "${boardDir}/jtag_debug_bscan.v"
            "rtl/ddr3_controller.v"
            "rtl/ddr3_phy.v"
            "rtl/ddr3_top.v"
            "${boardDir}/clk_wiz.v"
          ];
        };

        src = self;
        uberddr3SdfCompare = pkgs.writeShellApplication {
          name = "uberddr3-sdf-compare";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            exec python3 ${src}/scripts/uberddr3_sdf_compare.py "$@"
          '';
        };
        uberddr3SdfMetrics = pkgs.writeShellApplication {
          name = "uberddr3-sdf-metrics";
          runtimeInputs = [ pkgs.python3 sdfToolkit ];
          text = ''
            exec python3 ${src}/scripts/uberddr3_sdf_metrics.py "$@"
          '';
        };
        ypcbSrcs = lib.concatStringsSep " " ypcb.sources;

        writeToolMetadata = ''
          {
            echo '{'
            echo '  "part": "${ypcb.part}",'
            echo '  "dbpart": "${ypcb.dbpart}",'
            echo '  "family": "${ypcb.family}",'
            echo '  "top": "${ypcb.top}",'
            echo '  "bist_mode": 2,'
            echo '  "byte_lanes": 2,'
            echo '  "bist_test_datamask": 0,'
            echo '  "datamask_evidence": "YPCB MIG configuration uses <DataMask>0</DataMask>",'
            echo '  "yosys_version": '"$(yosys -V | ${pkgs.jq}/bin/jq -Rs .)"','
            echo '  "nextpnr_version": '"$(nextpnr-xilinx --version 2>&1 | head -1 | ${pkgs.jq}/bin/jq -Rs .)"','
            echo '  "source_sha256": "'"$(sha256sum ${ypcbSrcs} | sha256sum | cut -d ' ' -f 1)"'"'
            echo '}'
          } > metadata/toolchain.json
        '';

        mkYosysJson = { name, verilogDefines ? "" }: pkgs.runCommand name {
          nativeBuildInputs = [ pkgs.yosys pkgs.jq pkgs.coreutils ];
        } ''
          cp -R ${src} src
          chmod -R u+w src
          cd src
          mkdir -p $out metadata
          yosys -l metadata/yosys.log -p "read_verilog ${verilogDefines} ${ypcbSrcs}; synth_xilinx -flatten -abc9 -arch xc7 -top ${ypcb.top}; stat; write_json $out/${ypcb.project}.json"
          sha256sum $out/${ypcb.project}.json > metadata/yosys-json.sha256
          ${writeToolMetadata}
          echo ${builtins.toJSON verilogDefines} > metadata/verilog-defines.json
          cp -R metadata $out/metadata
        '';

        ypcbDdr3YosysJson = mkYosysJson { name = "ypcb-ddr3-yosys-json"; };
        ypcbDdr3IdelayStableBeforeLdYosysJson = mkYosysJson {
          name = "ypcb-ddr3-yosys-json-idelay-stable-before-ld";
          verilogDefines = "-DUBERDDR3_IDELAY_STABLE_BEFORE_LD";
        };
        ypcbDdr3IdelayLoadHandshakeYosysJson = mkYosysJson {
          name = "ypcb-ddr3-yosys-json-idelay-load-handshake";
          verilogDefines = "-DUBERDDR3_IDELAY_LOAD_HANDSHAKE";
        };

        ypcbDdr3Chipdb = pkgs.runCommand "ypcb-ddr3-chipdb" {
          nativeBuildInputs = [ pkgs.pypy3 nextpnrXilinx pkgs.coreutils ];
          PRJXRAY_DB_DIR = patchedPrjxrayDb;
        } ''
          mkdir -p $out metadata
          pypy3 ${nextpnrXilinx}/share/nextpnr/python/bbaexport.py --device ${ypcb.part} --bba ${ypcb.dbpart}.bba
          bbasm -l ${ypcb.dbpart}.bba $out/${ypcb.dbpart}.bin
          sha256sum $out/${ypcb.dbpart}.bin > metadata/chipdb.sha256
          cp -R metadata $out/metadata
        '';

        mkNextpnrJson = { name, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null, assertLocks ? false, yosysJson ? ypcbDdr3YosysJson }:
          let
            seedArg = if seed == null then "" else "--seed ${toString seed}";
            placerArg = if placer == null then "" else "--placer ${placer}";
            routerArg = if router == null then "" else "--router ${router}";
            lockSetup = if lockFile == null then "" else ''
              python3 ${src}/${ypcb.boardDir}/scripts/generate_nextpnr_pre_place_bel_locks.py \
                --locks-json ${src}/${lockFile} \
                --out-py ypcb_bel_locks_pre_place.py
              prePlaceArg="--pre-place ypcb_bel_locks_pre_place.py"
            '';
            checkLockSetup = if lockFile == null || !assertLocks then "" else ''
              python3 ${src}/scripts/check_nextpnr_bel_locks.py \
                --locks-json ${src}/${lockFile} \
                --placed-json $out/${ypcb.project}.placed.json
            '';
          in pkgs.runCommand name {
            nativeBuildInputs = [ nextpnrXilinx pkgs.python3 pkgs.jq pkgs.coreutils ];
          } ''
            cp -R ${src}/${ypcb.boardDir}/${ypcb.project}.xdc .
            mkdir -p $out metadata
            prePlaceArg=""
            ${lockSetup}
            nextpnr-xilinx \
              --chipdb ${ypcbDdr3Chipdb}/${ypcb.dbpart}.bin \
              --xdc ${ypcb.project}.xdc \
              --json ${yosysJson}/${ypcb.project}.json \
              --write $out/${ypcb.project}.placed.json \
              --fasm $out/${ypcb.project}.fasm \
              --freq ${ypcb.freqMHz} \
              ${seedArg} ${placerArg} ${routerArg} ${pnrArgs} $prePlaceArg \
              2>&1 | tee metadata/nextpnr.log
            ${checkLockSetup}
            sha256sum $out/${ypcb.project}.placed.json > metadata/nextpnr-json.sha256
            grep -E "(Checksum|checksum|Placed|Routed|Error|Warning|Info: Device utilisation|Info: Critical path)" metadata/nextpnr.log > metadata/nextpnr-summary.txt || true
            OUT_JSON="$out/${ypcb.project}.placed.json" python3 - <<'PY' > metadata/cell-summary.json
import collections, json, os
with open(os.environ["OUT_JSON"], encoding="utf-8") as f:
    data = json.load(f)
mods = data.get("modules", {})
mod = next((m for m in mods.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"), next(iter(mods.values())))
cells = mod.get("cells", {})
types = collections.Counter(c.get("type", "") for c in cells.values())
bels = collections.Counter(str(c.get("attributes", {}).get("NEXTPNR_BEL", "")).split("/")[0] for c in cells.values() if c.get("attributes", {}).get("NEXTPNR_BEL"))
print(json.dumps({"cell_count": len(cells), "type_counts": dict(sorted(types.items())), "bel_site_counts": dict(sorted(bels.items()))}, indent=2, sort_keys=True))
PY
            cat > metadata/candidate.json <<META
{"seed": ${if seed == null then "null" else toString seed}, "placer": ${if placer == null then "null" else ''"${placer}"''}, "router": ${if router == null then "null" else ''"${router}"''}, "pnr_args": ${builtins.toJSON pnrArgs}, "lock_file": ${if lockFile == null then "null" else builtins.toJSON lockFile}, "yosys_json": "${yosysJson}"}
META
            cp -R metadata $out/metadata
          '';

        mkSdf = { name, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null, assertLocks ? false, cvc ? false, yosysJson ? ypcbDdr3YosysJson }:
          let
            seedArg = if seed == null then "" else "--seed ${toString seed}";
            placerArg = if placer == null then "" else "--placer ${placer}";
            routerArg = if router == null then "" else "--router ${router}";
            cvcArg = if cvc then "--sdf-cvc" else "";
            sdfFile = if cvc then "${ypcb.project}.cvc.sdf" else "${ypcb.project}.sdf";
            lockSetup = if lockFile == null then "" else ''
              python3 ${src}/${ypcb.boardDir}/scripts/generate_nextpnr_pre_place_bel_locks.py \
                --locks-json ${src}/${lockFile} \
                --out-py ypcb_bel_locks_pre_place.py
              prePlaceArg="--pre-place ypcb_bel_locks_pre_place.py"
            '';
            checkLockSetup = if lockFile == null || !assertLocks then "" else ''
              python3 ${src}/scripts/check_nextpnr_bel_locks.py \
                --locks-json ${src}/${lockFile} \
                --placed-json $out/${ypcb.project}.placed.json
            '';
          in pkgs.runCommand name {
            nativeBuildInputs = [ nextpnrXilinx pkgs.python3 pkgs.jq pkgs.coreutils ];
          } ''
            cp -R ${src}/${ypcb.boardDir}/${ypcb.project}.xdc .
            mkdir -p $out metadata
            prePlaceArg=""
            ${lockSetup}
            nextpnr-xilinx \
              --chipdb ${ypcbDdr3Chipdb}/${ypcb.dbpart}.bin \
              --xdc ${ypcb.project}.xdc \
              --json ${yosysJson}/${ypcb.project}.json \
              --write $out/${ypcb.project}.placed.json \
              --freq ${ypcb.freqMHz} \
              ${seedArg} ${placerArg} ${routerArg} ${pnrArgs} $prePlaceArg ${cvcArg} \
              --sdf $out/${sdfFile} \
              2>&1 | tee metadata/nextpnr-sdf.log
            ${checkLockSetup}
            sha256sum $out/${sdfFile} > metadata/sdf.sha256
            sha256sum $out/${ypcb.project}.placed.json > metadata/nextpnr-json.sha256
            grep -E "(Checksum|checksum|Placed|Routed|Error|Warning|Info: Device utilisation|Info: Critical path)" metadata/nextpnr-sdf.log > metadata/nextpnr-sdf-summary.txt || true
            cat > metadata/candidate.json <<META
{"seed": ${if seed == null then "null" else toString seed}, "placer": ${if placer == null then "null" else ''"${placer}"''}, "router": ${if router == null then "null" else ''"${router}"''}, "pnr_args": ${builtins.toJSON pnrArgs}, "lock_file": ${if lockFile == null then "null" else builtins.toJSON lockFile}, "sdf_cvc": ${if cvc then "true" else "false"}, "yosys_json": "${yosysJson}"}
META
            cp -R metadata $out/metadata
          '';

        mkFasm = { name, nextpnrJson }:
          pkgs.runCommand name {
            nativeBuildInputs = [ pkgs.coreutils ];
          } ''
            mkdir -p $out metadata
            cp ${nextpnrJson}/${ypcb.project}.fasm $out/${ypcb.project}.fasm
            sha256sum $out/${ypcb.project}.fasm > metadata/fasm.sha256
            cp -R ${nextpnrJson}/metadata metadata/nextpnr-json
            cp -R metadata $out/metadata
          '';

        mkFrames = { name, fasmDrv }:
          pkgs.runCommand name {
            nativeBuildInputs = [ prjxray fasm pkgs.python3Packages.pyyaml pkgs.python3Packages.simplejson pkgs.python3Packages.intervaltree pkgs.coreutils ];
            PRJXRAY_DB_DIR = patchedPrjxrayDb;
          } ''
            mkdir -p $out metadata
            export PYTHONPATH=${prjxray}/usr/share/python3:${fasm}:''${PYTHONPATH-}
            fasm2frames --part ${ypcb.part} --db-root ${patchedPrjxrayDb}/${ypcb.family} ${fasmDrv}/${ypcb.project}.fasm > $out/${ypcb.project}.frames
            sha256sum $out/${ypcb.project}.frames > metadata/frames.sha256
            cp -R ${fasmDrv}/metadata metadata/fasm
            cp -R metadata $out/metadata
          '';

        mkBitstream = { name, framesDrv }:
          pkgs.runCommand name {
            nativeBuildInputs = [ prjxray pkgs.coreutils ];
            PRJXRAY_DB_DIR = patchedPrjxrayDb;
          } ''
            mkdir -p $out metadata
            xc7frames2bit \
              --part_file ${patchedPrjxrayDb}/${ypcb.family}/${ypcb.part}/part.yaml \
              --part_name ${ypcb.part} \
              --frm_file ${framesDrv}/${ypcb.project}.frames \
              --output_file $out/${ypcb.project}_openxc7.bit
            sha256sum $out/${ypcb.project}_openxc7.bit > metadata/bitstream.sha256
            cp -R ${framesDrv}/metadata metadata/frames
            cp -R metadata $out/metadata
          '';

        mkCandidate = { suffix, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null, assertLocks ? false, yosysJson ? ypcbDdr3YosysJson }:
          let
            pnr = mkNextpnrJson { name = "ypcb-ddr3-nextpnr-json-${suffix}"; inherit seed pnrArgs placer router lockFile assertLocks yosysJson; };
            fasmDrv = mkFasm { name = "ypcb-ddr3-fasm-${suffix}"; nextpnrJson = pnr; };
            frames = mkFrames { name = "ypcb-ddr3-frames-${suffix}"; inherit fasmDrv; };
            bitstream = mkBitstream { name = "ypcb-ddr3-bitstream-${suffix}"; framesDrv = frames; };
            sdf = mkSdf { name = "ypcb-ddr3-sdf-${suffix}"; inherit seed pnrArgs placer router lockFile assertLocks yosysJson; };
            cvcSdf = mkSdf { name = "ypcb-ddr3-cvc-sdf-${suffix}"; inherit seed pnrArgs placer router lockFile assertLocks yosysJson; cvc = true; };
          in { inherit pnr fasmDrv frames bitstream sdf cvcSdf; };

        baseline = mkCandidate { suffix = "baseline"; };
        robustLock = "example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_reset_release_locks.json";
        idelayControlLock = "example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_idelay_cntvaluein_locks_seed3.json";
        idelayControlFullLock = "example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_idelay_control_locks_seed3.json";
        cntvaluein3SkewLock = "example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_cntvaluein3_skew_locks_seed3.json";
        seedMatrix = map toString (lib.range 1 60);
        seedCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate { suffix = "seed-${seed}"; seed = lib.toInt seed; });
        robustCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-robust";
            seed = lib.toInt seed;
            lockFile = robustLock;
            pnrArgs = "--no-tmdriv";
          });
        noTmdrivCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-no-tmdriv";
            seed = lib.toInt seed;
            pnrArgs = "--no-tmdriv";
          });
        resetLockOnlyCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-reset-locks-only";
            seed = lib.toInt seed;
            lockFile = robustLock;
          });
        idelayControlLockCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-idelay-control-locked";
            seed = lib.toInt seed;
            lockFile = idelayControlLock;
            assertLocks = true;
          });
        idelayControlFullLockCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-idelay-control-full-locked";
            seed = lib.toInt seed;
            lockFile = idelayControlFullLock;
            assertLocks = true;
          });
        cntvaluein3SkewLockCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-cntvaluein3-skew-locked";
            seed = lib.toInt seed;
            lockFile = cntvaluein3SkewLock;
            assertLocks = true;
          });
        idelayStableBeforeLdCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-idelay-stable-before-ld";
            seed = lib.toInt seed;
            yosysJson = ypcbDdr3IdelayStableBeforeLdYosysJson;
          });
        idelayLoadHandshakeCandidates = lib.genAttrs seedMatrix (seed:
          mkCandidate {
            suffix = "seed-${seed}-idelay-load-handshake";
            seed = lib.toInt seed;
            yosysJson = ypcbDdr3IdelayLoadHandshakeYosysJson;
          });
        seedBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}" candidate.bitstream) seedCandidates;
        seedPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}" candidate.pnr) seedCandidates;
        seedFasms = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-seed-${seed}" candidate.fasmDrv) seedCandidates;
        seedSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}" candidate.sdf) seedCandidates;
        seedCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}" candidate.cvcSdf) seedCandidates;
        robustBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-robust" candidate.bitstream) robustCandidates;
        robustPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}-robust" candidate.pnr) robustCandidates;
        robustFasms = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-seed-${seed}-robust" candidate.fasmDrv) robustCandidates;
        robustSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-robust" candidate.sdf) robustCandidates;
        robustCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-robust" candidate.cvcSdf) robustCandidates;
        noTmdrivBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-no-tmdriv" candidate.bitstream) noTmdrivCandidates;
        noTmdrivSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-no-tmdriv" candidate.sdf) noTmdrivCandidates;
        noTmdrivCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-no-tmdriv" candidate.cvcSdf) noTmdrivCandidates;
        resetLockOnlyBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-reset-locks-only" candidate.bitstream) resetLockOnlyCandidates;
        resetLockOnlySdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-reset-locks-only" candidate.sdf) resetLockOnlyCandidates;
        resetLockOnlyCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-reset-locks-only" candidate.cvcSdf) resetLockOnlyCandidates;
        idelayControlLockPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}-idelay-control-locked" candidate.pnr) idelayControlLockCandidates;
        idelayControlLockBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-idelay-control-locked" candidate.bitstream) idelayControlLockCandidates;
        idelayControlLockSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-idelay-control-locked" candidate.sdf) idelayControlLockCandidates;
        idelayControlLockCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-idelay-control-locked" candidate.cvcSdf) idelayControlLockCandidates;
        idelayControlFullLockPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}-idelay-control-full-locked" candidate.pnr) idelayControlFullLockCandidates;
        idelayControlFullLockBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-idelay-control-full-locked" candidate.bitstream) idelayControlFullLockCandidates;
        idelayControlFullLockSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-idelay-control-full-locked" candidate.sdf) idelayControlFullLockCandidates;
        idelayControlFullLockCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-idelay-control-full-locked" candidate.cvcSdf) idelayControlFullLockCandidates;
        cntvaluein3SkewLockPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}-cntvaluein3-skew-locked" candidate.pnr) cntvaluein3SkewLockCandidates;
        cntvaluein3SkewLockBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-cntvaluein3-skew-locked" candidate.bitstream) cntvaluein3SkewLockCandidates;
        cntvaluein3SkewLockSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-cntvaluein3-skew-locked" candidate.sdf) cntvaluein3SkewLockCandidates;
        cntvaluein3SkewLockCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-cntvaluein3-skew-locked" candidate.cvcSdf) cntvaluein3SkewLockCandidates;
        idelayStableBeforeLdPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}-idelay-stable-before-ld" candidate.pnr) idelayStableBeforeLdCandidates;
        idelayStableBeforeLdBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-idelay-stable-before-ld" candidate.bitstream) idelayStableBeforeLdCandidates;
        idelayStableBeforeLdSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-idelay-stable-before-ld" candidate.sdf) idelayStableBeforeLdCandidates;
        idelayStableBeforeLdCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-idelay-stable-before-ld" candidate.cvcSdf) idelayStableBeforeLdCandidates;
        idelayLoadHandshakePnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}-idelay-load-handshake" candidate.pnr) idelayLoadHandshakeCandidates;
        idelayLoadHandshakeBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-idelay-load-handshake" candidate.bitstream) idelayLoadHandshakeCandidates;
        idelayLoadHandshakeSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}-idelay-load-handshake" candidate.sdf) idelayLoadHandshakeCandidates;
        idelayLoadHandshakeCvcSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-cvc-sdf-seed-${seed}-idelay-load-handshake" candidate.cvcSdf) idelayLoadHandshakeCandidates;
      in {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ openXc7Shell ];
          shellHook = ''
            ${openXc7Shell.shellHook or ""}
            export PRJXRAY_DB_DIR="${patchedPrjxrayDb}"
          '';
        };

        apps = {
          sdf-toolkit = {
            type = "app";
            program = "${sdfToolkit}/bin/sdf-toolkit";
          };
          uberddr3-sdf-compare = {
            type = "app";
            program = "${uberddr3SdfCompare}/bin/uberddr3-sdf-compare";
          };
          uberddr3-sdf-metrics = {
            type = "app";
            program = "${uberddr3SdfMetrics}/bin/uberddr3-sdf-metrics";
          };
        };

        checks = {
          icarus-compile = pkgs.runCommand "uberddr3-icarus-compile" {
            nativeBuildInputs = [
              pkgs.coreutils
              pkgs.iverilog
            ];
          } "
            cp -R ${src} src
            chmod -R u+w src
            cd src/testbench/icarus_sim
            iverilog -o uberddr3_sim -g2012 -DNO_TEST_MODEL -DSIM_MODEL -s ddr3_dimm_micron_sim -I ../ ../ddr3_dimm_micron_sim.sv ../ddr3.sv ../models/IDELAYCTRL_model.v ../models/IDELAYE2_model.v ../models/IOBUF_DCIEN_model.v ../models/IOBUF_model.v ../models/IOBUFDS_DCIEN_model.v ../models/IOBUFDS_model.v ../models/ISERDESE2_model.v ../models/OBUFDS_model.v ../models/ODELAYE2_model.v ../models/OSERDESE2_model.v ../models/OBUF_model.v ../../rtl/ddr3_top.v ../../rtl/ddr3_controller.v ../../rtl/ddr3_phy.v ../ddr3_module.sv
            mkdir -p $out
            cp uberddr3_sim $out/
            echo Icarus elaboration passed > $out/summary.txt
          ";

          formal-ecc = pkgs.runCommand "uberddr3-formal-ecc" {
            nativeBuildInputs = [
              pkgs.sby
              pkgs.yosys
              pkgs.boolector
              pkgs.yices
              pkgs.coreutils
            ];
          } "
            cp -R ${src} src
            chmod -R u+w src
            cd src
            sby -f -d formal-ecc formal/ecc.sby
            mkdir -p \"$out\"
            cp -R formal-ecc \"$out/\"
          ";

          formal-ddr3-singleconfig-bmc = pkgs.runCommand "uberddr3-formal-ddr3-singleconfig-bmc" {
            nativeBuildInputs = [
              pkgs.sby
              pkgs.yosys
              pkgs.boolector
              pkgs.yices
              pkgs.gnused
              pkgs.coreutils
            ];
          } "
            cp -R ${src} src
            chmod -R u+w src
            cd src
            sed \"s|^mode prove$|mode bmc|\" formal/ddr3_singleconfig.sby > ddr3_singleconfig_bmc.sby
            sby -f -d formal-ddr3-singleconfig-bmc ddr3_singleconfig_bmc.sby
            mkdir -p \"$out\"
            cp -R formal-ddr3-singleconfig-bmc \"$out/\"
          ";

          formal-calibration-failures = pkgs.runCommand "uberddr3-formal-calibration-failures" {
            nativeBuildInputs = [
              pkgs.sby
              pkgs.yosys
              pkgs.boolector
              pkgs.yices
              pkgs.coreutils
            ];
          } "
            cp -R ${src} src
            chmod -R u+w src
            cd src
            sby -f -d formal-calibration-failures formal/ddr3_calibration_failures.sby
            mkdir -p \"$out\"
            cp -R formal-calibration-failures \"$out/\"
          ";
        };

        packages = {
          sdf-toolkit = sdfToolkit;
          uberddr3-sdf-compare = uberddr3SdfCompare;
          uberddr3-sdf-metrics = uberddr3SdfMetrics;
          ypcb-ddr3-yosys-json = ypcbDdr3YosysJson;
          ypcb-ddr3-yosys-json-idelay-stable-before-ld = ypcbDdr3IdelayStableBeforeLdYosysJson;
          ypcb-ddr3-yosys-json-idelay-load-handshake = ypcbDdr3IdelayLoadHandshakeYosysJson;
          ypcb-ddr3-chipdb = ypcbDdr3Chipdb;
          ypcb-ddr3-nextpnr-json = baseline.pnr;
          ypcb-ddr3-nextpnr-json-baseline = baseline.pnr;
          ypcb-ddr3-fasm = baseline.fasmDrv;
          ypcb-ddr3-fasm-baseline = baseline.fasmDrv;
          ypcb-ddr3-frames = baseline.frames;
          ypcb-ddr3-frames-baseline = baseline.frames;
          ypcb-ddr3-bitstream = baseline.bitstream;
          ypcb-ddr3-bitstream-baseline = baseline.bitstream;
          ypcb-ddr3-sdf = baseline.sdf;
          ypcb-ddr3-sdf-baseline = baseline.sdf;
          ypcb-ddr3-cvc-sdf = baseline.cvcSdf;
          ypcb-ddr3-cvc-sdf-baseline = baseline.cvcSdf;
          default = baseline.bitstream;
        } // seedBitstreams // seedPnrs // seedFasms // seedSdfs // seedCvcSdfs
          // robustBitstreams
          // robustPnrs
          // robustFasms
          // robustSdfs
          // robustCvcSdfs
          // noTmdrivBitstreams
          // noTmdrivSdfs
          // noTmdrivCvcSdfs
          // resetLockOnlyBitstreams
          // resetLockOnlySdfs
          // resetLockOnlyCvcSdfs
          // idelayControlLockPnrs
          // idelayControlLockBitstreams
          // idelayControlLockSdfs
          // idelayControlLockCvcSdfs
          // idelayControlFullLockPnrs
          // idelayControlFullLockBitstreams
          // idelayControlFullLockSdfs
          // idelayControlFullLockCvcSdfs
          // cntvaluein3SkewLockPnrs
          // cntvaluein3SkewLockBitstreams
          // cntvaluein3SkewLockSdfs
          // cntvaluein3SkewLockCvcSdfs
          // idelayStableBeforeLdPnrs
          // idelayStableBeforeLdBitstreams
          // idelayStableBeforeLdSdfs
          // idelayStableBeforeLdCvcSdfs
          // idelayLoadHandshakePnrs
          // idelayLoadHandshakeBitstreams
          // idelayLoadHandshakeSdfs
          // idelayLoadHandshakeCvcSdfs;
      });
}
