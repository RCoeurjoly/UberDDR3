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
        nextpnrXilinx = openXc7Packages.nextpnr-xilinx;
        prjxray = openXc7Packages.prjxray;
        fasm = openXc7Packages.fasm;
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

        mkYosysJson = name: pkgs.runCommand name {
          nativeBuildInputs = [ pkgs.yosys pkgs.jq pkgs.coreutils ];
        } ''
          cp -R ${src} src
          chmod -R u+w src
          cd src
          mkdir -p $out metadata
          yosys -l metadata/yosys.log -p "read_verilog ${ypcbSrcs}; synth_xilinx -flatten -abc9 -arch xc7 -top ${ypcb.top}; stat; write_json $out/${ypcb.project}.json"
          sha256sum $out/${ypcb.project}.json > metadata/yosys-json.sha256
          ${writeToolMetadata}
          cp -R metadata $out/metadata
        '';

        ypcbDdr3YosysJson = mkYosysJson "ypcb-ddr3-yosys-json";

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

        mkNextpnrJson = { name, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null }:
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
              --json ${ypcbDdr3YosysJson}/${ypcb.project}.json \
              --write $out/${ypcb.project}.placed.json \
              --fasm $out/${ypcb.project}.fasm \
              --freq ${ypcb.freqMHz} \
              ${seedArg} ${placerArg} ${routerArg} ${pnrArgs} $prePlaceArg \
              2>&1 | tee metadata/nextpnr.log
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
{"seed": ${if seed == null then "null" else toString seed}, "placer": ${if placer == null then "null" else ''"${placer}"''}, "router": ${if router == null then "null" else ''"${router}"''}, "pnr_args": ${builtins.toJSON pnrArgs}, "lock_file": ${if lockFile == null then "null" else builtins.toJSON lockFile}}
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

        mkCandidate = { suffix, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null }:
          let
            pnr = mkNextpnrJson { name = "ypcb-ddr3-nextpnr-json-${suffix}"; inherit seed pnrArgs placer router lockFile; };
            fasmDrv = mkFasm { name = "ypcb-ddr3-fasm-${suffix}"; nextpnrJson = pnr; };
            frames = mkFrames { name = "ypcb-ddr3-frames-${suffix}"; inherit fasmDrv; };
            bitstream = mkBitstream { name = "ypcb-ddr3-bitstream-${suffix}"; framesDrv = frames; };
          in { inherit pnr fasmDrv frames bitstream; };

        baseline = mkCandidate { suffix = "baseline"; };
        resetReleaseLock = "example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_reset_release_locks.json";
        seed1ResetDqsIdelayLock = "example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_seed1_reset_dqs_idelay_locks.json";
        seedCandidates = lib.genAttrs [ "1" "2" "3" "4" "5" ] (seed:
          mkCandidate { suffix = "seed-${seed}"; seed = lib.toInt seed; });
        resetReleaseLutSeed2LockCandidates = lib.genAttrs [ "1" "2" "3" "4" "5" ] (seed:
          mkCandidate {
            suffix = "seed-${seed}-reset-release-lut-seed2-lock";
            seed = lib.toInt seed;
            lockFile = if seed == "1" then seed1ResetDqsIdelayLock else resetReleaseLock;
          });
        seedBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}" candidate.bitstream) seedCandidates;
        seedPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}" candidate.pnr) seedCandidates;
        seedFasms = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-seed-${seed}" candidate.fasmDrv) seedCandidates;
        resetReleaseLutSeed2LockBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}-reset-release-lut-seed2-lock" candidate.bitstream) resetReleaseLutSeed2LockCandidates;
        resetReleaseLutSeed2LockPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}-reset-release-lut-seed2-lock" candidate.pnr) resetReleaseLutSeed2LockCandidates;
        resetReleaseLutSeed2LockFasms = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-seed-${seed}-reset-release-lut-seed2-lock" candidate.fasmDrv) resetReleaseLutSeed2LockCandidates;
      in {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ openXc7Shell ];
          shellHook = ''
            ${openXc7Shell.shellHook or ""}
            export PRJXRAY_DB_DIR="${patchedPrjxrayDb}"
          '';
        };

        packages = {
          ypcb-ddr3-yosys-json = ypcbDdr3YosysJson;
          ypcb-ddr3-chipdb = ypcbDdr3Chipdb;
          ypcb-ddr3-nextpnr-json = baseline.pnr;
          ypcb-ddr3-nextpnr-json-baseline = baseline.pnr;
          ypcb-ddr3-fasm = baseline.fasmDrv;
          ypcb-ddr3-fasm-baseline = baseline.fasmDrv;
          ypcb-ddr3-frames = baseline.frames;
          ypcb-ddr3-frames-baseline = baseline.frames;
          ypcb-ddr3-bitstream = baseline.bitstream;
          ypcb-ddr3-bitstream-baseline = baseline.bitstream;
          default = baseline.bitstream;
        } // seedBitstreams // seedPnrs // seedFasms
          // resetReleaseLutSeed2LockBitstreams
          // resetReleaseLutSeed2LockPnrs
          // resetReleaseLutSeed2LockFasms;
      });
}
