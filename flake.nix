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
            "${boardDir}/jtag_trace_bscan.v"
            "${boardDir}/ypcb_debug_wb_scope.v"
            "${boardDir}/ypcb_debug_axi_lite.v"
            "rtl/ddr3_controller.v"
            "rtl/ddr3_phy.v"
            "rtl/ddr3_top.v"
            "${boardDir}/clk_wiz.v"
          ];
        };

        src = self;
        ypcbSrcs = lib.concatStringsSep " " ypcb.sources;

        writeToolMetadata = { byteLanes ? 2, bistMode ? 2 }: ''
          {
            echo '{'
            echo '  "part": "${ypcb.part}",'
            echo '  "dbpart": "${ypcb.dbpart}",'
            echo '  "family": "${ypcb.family}",'
            echo '  "top": "${ypcb.top}",'
            echo '  "bist_mode": ${toString bistMode},'
            echo '  "byte_lanes": ${toString byteLanes},'
            echo '  "bist_test_datamask": 0,'
            echo '  "datamask_evidence": "YPCB MIG configuration uses <DataMask>0</DataMask>",'
            echo '  "yosys_version": '"$(yosys -V | ${pkgs.jq}/bin/jq -Rs .)"','
            echo '  "nextpnr_version": '"$(nextpnr-xilinx --version 2>&1 | head -1 | ${pkgs.jq}/bin/jq -Rs .)"','
            echo '  "source_sha256": "'"$(sha256sum ${ypcbSrcs} | sha256sum | cut -d ' ' -f 1)"'"'
            echo '}'
          } > metadata/toolchain.json
        '';

        mkYosysJson = { name, verilogDefines ? "", byteLanes ? 2, bistMode ? 2 }: pkgs.runCommand name {
          nativeBuildInputs = [ pkgs.yosys pkgs.jq pkgs.coreutils ];
        } ''
          cp -R ${src} src
          chmod -R u+w src
          cd src
          mkdir -p $out metadata
          yosys -l metadata/yosys.log -p "read_verilog ${verilogDefines} ${ypcbSrcs}; synth_xilinx -flatten -abc9 -arch xc7 -top ${ypcb.top}; stat; write_json $out/${ypcb.project}.json"
          sha256sum $out/${ypcb.project}.json > metadata/yosys-json.sha256
          echo ${builtins.toJSON verilogDefines} > metadata/verilog-defines.json
          ${writeToolMetadata { inherit byteLanes bistMode; }}
          cp -R metadata $out/metadata
        '';

        ypcbDdr3YosysJson = mkYosysJson { name = "ypcb-ddr3-yosys-json"; };
        ypcbDdr3DebugYosysJson = mkYosysJson {
          name = "ypcb-ddr3-yosys-json-debug-jtag";
          verilogDefines = "-DUBERDDR3_DEBUG_JTAG";
        };
        ypcbDdr3PanopticonYosysJson = mkYosysJson {
          name = "ypcb-ddr3-yosys-json-panopticon";
          verilogDefines = "-DUBERDDR3_DEBUG_JTAG -DUBERDDR3_PANOPTICON";
        };
        ypcbDdr3TraceScopeYosysJson = mkYosysJson {
          name = "ypcb-ddr3-yosys-json-trace-scope";
          verilogDefines = "-DUBERDDR3_DEBUG_JTAG -DUBERDDR3_PANOPTICON -DUBERDDR3_TRACE_SCOPE";
        };
        ypcbDdr3DefaultTopParams = {
          controllerClkPeriod = 12000;
          ddr3ClkPeriod = 3000;
          rowBits = 12;
          colBits = 10;
          baBits = 3;
          byteLanes = 1;
          auxWidth = 4;
          wb2AddrBits = 7;
          wb2DataBits = 32;
          micronSim = 0;
          odelaySupported = 0;
          secondWishbone = 0;
          wbError = 0;
          bistMode = 0;
          bistTestDatamask = 0;
          eccEnable = 0;
          dic = "2'b00";
          rttNom = "3'b000";
          selfRefresh = "2'b00";
          speedBin = 1;
          sdramCapacity = 4;
        };
        mkYpcbDdr3TopParamVariant = entry:
          ypcbDdr3DefaultTopParams // entry.overrides // {
            inherit (entry) suffix label axis;
            notes = entry.notes or "";
          };
        mkYpcbDdr3GeneratedVariant = index: entry:
          mkYpcbDdr3TopParamVariant {
            suffix = "panopticon-p${lib.fixedWidthNumber 3 index}-${entry.name}";
            label = entry.label;
            axis = entry.axis;
            overrides = entry.overrides;
            notes = entry.notes or "";
          };

        # Ordered to match the upstream README "Instantiate Design" parameter table.
        # This is an ordered one-axis-at-a-time sweep: baseline first, then each
        # non-default value for each parameter in README order. It avoids a huge
        # Cartesian product while keeping the parameter domains explicit and easy
        # to widen when we intentionally want more combinations.
        ypcbDdr3TopParameterSweepEntries = [
          { name = "baseline-low"; label = "baseline-low"; axis = "baseline"; overrides = { }; notes = "Lowest-cost YPCB-compatible starting point; BIST disabled."; }
        ]
        ++ (map (clock: {
          name = clock.name;
          label = clock.label;
          axis = "clockPeriod";
          overrides = clock.overrides;
        }) [
          { name = "clk100"; label = "controller-clock-100mhz"; overrides = { controllerClkPeriod = 10000; ddr3ClkPeriod = 2500; speedBin = 3; }; }
        ])
        ++ (map (rowBits: {
          name = "row${toString rowBits}";
          label = "row-bits-${toString rowBits}";
          axis = "rowBits";
          overrides = { inherit rowBits; };
        }) [ 13 14 15 16 ])
        ++ (map (colBits: {
          name = "col${toString colBits}";
          label = "col-bits-${toString colBits}";
          axis = "colBits";
          overrides = { inherit colBits; };
        }) [ 11 12 ])
        ++ (map (byteLanes: {
          name = "lanes${toString byteLanes}";
          label = "byte-lanes-${toString byteLanes}";
          axis = "byteLanes";
          overrides = { inherit byteLanes; };
        }) [ 2 4 8 ])
        ++ (map (auxWidth: {
          name = "aux${toString auxWidth}";
          label = "aux-width-${toString auxWidth}";
          axis = "auxWidth";
          overrides = { inherit auxWidth; };
        }) [ 8 ])
        ++ (map (wb2AddrBits: {
          name = "wb2a${toString wb2AddrBits}";
          label = "wb2-addr-${toString wb2AddrBits}";
          axis = "wb2AddrBits";
          overrides = { inherit wb2AddrBits; };
        }) [ 32 ])
        ++ (map (secondWishbone: {
          name = "secondwb${toString secondWishbone}";
          label = "second-wishbone-${toString secondWishbone}";
          axis = "secondWishbone";
          overrides = { inherit secondWishbone; };
        }) [ 1 ])
        ++ (map (wbError: {
          name = "wberr${toString wbError}";
          label = "wb-error-${toString wbError}";
          axis = "wbError";
          overrides = { inherit wbError; };
        }) [ 1 ])
        ++ (map (bistMode: {
          name = "bist${toString bistMode}";
          label = "bist-mode-${toString bistMode}";
          axis = "bistMode";
          overrides = { inherit bistMode; };
        }) [ 1 2 ])
        ++ (map (bistTestDatamask: {
          name = "datamask${toString bistTestDatamask}";
          label = "bist-datamask-${toString bistTestDatamask}";
          axis = "bistTestDatamask";
          overrides = { inherit bistTestDatamask; };
          notes = "May be board-incompatible when MIG reports DataMask disabled; included for parameter coverage.";
        }) [ 1 ])
        ++ (map (eccEnable: {
          name = "ecc${toString eccEnable}";
          label = "ecc-${toString eccEnable}";
          axis = "eccEnable";
          overrides = { inherit eccEnable; };
        }) [ 1 2 3 ])
        ++ (map (dic: {
          name = "dic${toString dic.code}";
          label = "dic-${dic.label}";
          axis = "dic";
          overrides = { dic = dic.value; };
        }) [
          { value = "2'b01"; code = 1; label = "rzq7"; }
        ])
        ++ (map (rttNom: {
          name = "rtt${toString rttNom.code}";
          label = "rtt-nom-${rttNom.label}";
          axis = "rttNom";
          overrides = { rttNom = rttNom.value; };
        }) [
          { value = "3'b001"; code = 1; label = "rzq4"; }
          { value = "3'b010"; code = 2; label = "rzq2"; }
          { value = "3'b011"; code = 3; label = "rzq6"; }
        ])
        ++ (map (selfRefresh: {
          name = "sref${toString selfRefresh.code}";
          label = "self-refresh-${selfRefresh.label}";
          axis = "selfRefresh";
          overrides = { selfRefresh = selfRefresh.value; };
        }) [
          { value = "2'b01"; code = 1; label = "64"; }
          { value = "2'b10"; code = 2; label = "128"; }
          { value = "2'b11"; code = 3; label = "256"; }
        ])
        ++ (map (speedBin: {
          name = "speed${toString speedBin}";
          label = "speed-bin-${toString speedBin}";
          axis = "speedBin";
          overrides = { inherit speedBin; };
        }) [ 2 3 ])
        ++ (map (sdramCapacity: {
          name = "cap${toString sdramCapacity}";
          label = "sdram-capacity-${toString sdramCapacity}";
          axis = "sdramCapacity";
          overrides = { inherit sdramCapacity; };
        }) [ 0 1 2 3 5 6 ]);

        ypcbDdr3PanopticonSweepVariants = lib.imap0 mkYpcbDdr3GeneratedVariant ypcbDdr3TopParameterSweepEntries;
        ypcbDdr3PanopticonTraceVariants = [
          { suffix = "panopticon-trace-lanes1-bist1"; byteLanes = 1; bistMode = 1; }
        ];
        mkYpcbPanopticonVariantDefines = {
          controllerClkPeriod, ddr3ClkPeriod, rowBits, colBits, baBits, byteLanes,
          auxWidth, wb2AddrBits, wb2DataBits, micronSim, odelaySupported,
          secondWishbone, wbError, bistMode, bistTestDatamask, eccEnable, dic,
          rttNom, selfRefresh, speedBin, sdramCapacity, traceScope ? false, ...
        }:
          "-DUBERDDR3_DEBUG_JTAG -DUBERDDR3_PANOPTICON "
          + lib.optionalString traceScope "-DUBERDDR3_TRACE_SCOPE "
          + "-DUBERDDR3_YPCB_CONTROLLER_CLK_PERIOD=${toString controllerClkPeriod} "
          + "-DUBERDDR3_YPCB_DDR3_CLK_PERIOD=${toString ddr3ClkPeriod} "
          + "-DUBERDDR3_YPCB_ROW_BITS=${toString rowBits} "
          + "-DUBERDDR3_YPCB_COL_BITS=${toString colBits} "
          + "-DUBERDDR3_YPCB_BA_BITS=${toString baBits} "
          + "-DUBERDDR3_YPCB_BYTE_LANES=${toString byteLanes} "
          + "-DUBERDDR3_YPCB_AUX_WIDTH=${toString auxWidth} "
          + "-DUBERDDR3_YPCB_WB2_ADDR_BITS=${toString wb2AddrBits} "
          + "-DUBERDDR3_YPCB_WB2_DATA_BITS=${toString wb2DataBits} "
          + "-DUBERDDR3_YPCB_MICRON_SIM=${toString micronSim} "
          + "-DUBERDDR3_YPCB_ODELAY_SUPPORTED=${toString odelaySupported} "
          + "-DUBERDDR3_YPCB_SECOND_WISHBONE=${toString secondWishbone} "
          + "-DUBERDDR3_YPCB_WB_ERROR=${toString wbError} "
          + "-DUBERDDR3_YPCB_BIST_MODE=${toString bistMode} "
          + "-DUBERDDR3_YPCB_BIST_TEST_DATAMASK=${toString bistTestDatamask} "
          + "-DUBERDDR3_YPCB_ECC_ENABLE=${toString eccEnable} "
          + "-DUBERDDR3_YPCB_DIC=${dic} "
          + "-DUBERDDR3_YPCB_RTT_NOM=${rttNom} "
          + "-DUBERDDR3_YPCB_SELF_REFRESH=${selfRefresh} "
          + "-DUBERDDR3_YPCB_SPEED_BIN=${toString speedBin} "
          + "-DUBERDDR3_YPCB_SDRAM_CAPACITY=${toString sdramCapacity}";
        ypcbDdr3PanopticonSweepYosysJsons = lib.listToAttrs (map (variant:
          lib.nameValuePair variant.suffix (mkYosysJson {
            name = "ypcb-ddr3-yosys-json-${variant.suffix}";
            verilogDefines = mkYpcbPanopticonVariantDefines variant;
            inherit (variant) byteLanes bistMode;
          })
        ) ypcbDdr3PanopticonSweepVariants);
        ypcbDdr3PanopticonTraceYosysJsons = lib.listToAttrs (map (variant:
          lib.nameValuePair variant.suffix (mkYosysJson {
            name = "ypcb-ddr3-yosys-json-${variant.suffix}";
            verilogDefines = mkYpcbPanopticonVariantDefines (variant // { traceScope = true; });
            inherit (variant) byteLanes bistMode;
          })
        ) ypcbDdr3PanopticonTraceVariants);
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

        mkNextpnrJson = { name, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null, yosysJson ? ypcbDdr3YosysJson }:
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
              --json ${yosysJson}/${ypcb.project}.json \
              --write $out/${ypcb.project}.placed.json \
              --fasm $out/${ypcb.project}.fasm \
              --freq ${ypcb.freqMHz} \
              ${seedArg} ${placerArg} ${routerArg} ${pnrArgs} $prePlaceArg \
              2>&1 | tee metadata/nextpnr.log
            sha256sum $out/${ypcb.project}.placed.json > metadata/nextpnr-json.sha256
            grep -E "(Checksum|checksum|Placed|Routed|Error|Warning|Info: Device utilisation|Info: Critical path)" metadata/nextpnr.log > metadata/nextpnr-summary.txt || true
            cat > metadata/candidate.json <<META
{"seed": ${if seed == null then "null" else toString seed}, "placer": ${if placer == null then "null" else ''"${placer}"''}, "router": ${if router == null then "null" else ''"${router}"''}, "pnr_args": ${builtins.toJSON pnrArgs}, "lock_file": ${if lockFile == null then "null" else builtins.toJSON lockFile}, "yosys_json": "${yosysJson}"}
META
            cp -R metadata $out/metadata
          '';

        mkSdf = { name, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null, yosysJson ? ypcbDdr3YosysJson }:
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
              --json ${yosysJson}/${ypcb.project}.json \
              --write $out/${ypcb.project}.placed.json \
              --freq ${ypcb.freqMHz} \
              ${seedArg} ${placerArg} ${routerArg} ${pnrArgs} $prePlaceArg \
              --sdf $out/${ypcb.project}.sdf \
              2>&1 | tee metadata/nextpnr-sdf.log
            sha256sum $out/${ypcb.project}.sdf > metadata/sdf.sha256
            sha256sum $out/${ypcb.project}.placed.json > metadata/nextpnr-json.sha256
            grep -E "(Checksum|checksum|Placed|Routed|Error|Warning|Info: Device utilisation|Info: Critical path)" metadata/nextpnr-sdf.log > metadata/nextpnr-sdf-summary.txt || true
            cp -R metadata $out/metadata
          '';

        mkGateNetlist = { name, yosysJson }:
          pkgs.runCommand name {
            nativeBuildInputs = [ pkgs.yosys pkgs.coreutils ];
          } ''
            mkdir -p $out metadata
            yosys -l metadata/yosys-write-verilog.log -p "read_json ${yosysJson}/${ypcb.project}.json; write_verilog -noattr $out/${ypcb.project}_gate.v"
            sha256sum $out/${ypcb.project}_gate.v > metadata/gate-netlist.sha256
            cp -R ${yosysJson}/metadata metadata/yosys-json
            cp -R metadata $out/metadata
          '';

        icarusRtlSources = ''
          ${src}/testbench/models/IDELAYCTRL_model.v \
          ${src}/testbench/models/IDELAYE2_model.v \
          ${src}/testbench/models/IOBUF_DCIEN_model.v \
          ${src}/testbench/models/IOBUF_model.v \
          ${src}/testbench/models/IOBUFDS_DCIEN_model.v \
          ${src}/testbench/models/IOBUFDS_model.v \
          ${src}/testbench/models/ISERDESE2_model.v \
          ${src}/testbench/models/OBUFDS_model.v \
          ${src}/testbench/models/ODELAYE2_model.v \
          ${src}/testbench/models/OSERDESE2_model.v \
          ${src}/testbench/models/OBUF_model.v \
          ${src}/rtl/ddr3_top.v \
          ${src}/rtl/ddr3_controller.v \
          ${src}/rtl/ddr3_phy.v
        '';

        mkIcarusRtlBist = { name, runSimulation ? true }:
          pkgs.runCommand name {
            nativeBuildInputs = [ pkgs.iverilog pkgs.coreutils ];
          } ''
            mkdir -p $out work
            cd work
            iverilog -g2012 -o ypcb_rtl_bist.vvp \
              -DNO_TEST_MODEL -DSIM_MODEL \
              -s ypcb_rtl_bist_tb \
              -I ${src}/testbench \
              ${src}/testbench/ypcb_icarus/ypcb_rtl_bist_tb.sv \
              ${src}/testbench/ddr3.sv \
              ${icarusRtlSources} \
              > $out/iverilog.log 2>&1 || compile_rc=$?
            compile_rc="''${compile_rc:-0}"
            echo "$compile_rc" > $out/iverilog.returncode
            if [ "$compile_rc" -eq 0 ] && [ "${if runSimulation then "1" else "0"}" -eq 1 ]; then
              timeout 120s vvp -n ypcb_rtl_bist.vvp > $out/vvp.log 2>&1 || run_rc=$?
            elif [ "$compile_rc" -eq 0 ]; then
              echo "Icarus elaboration passed; simulation not run by this target" > $out/vvp.log
              run_rc=0
            else
              echo "iverilog compile failed; vvp not run" > $out/vvp.log
              run_rc=125
            fi
            run_rc="''${run_rc:-0}"
            echo "$run_rc" > $out/vvp.returncode
            cp ypcb_rtl_bist.vvp $out/ 2>/dev/null || true
            cat > $out/README.md <<README
# YPCB RTL BIST Icarus result

- stage: rtl-bist
- micron_model: testbench/ddr3.sv
- iverilog return code: $compile_rc
- vvp return code: $run_rc
- timeout return code is 124
- compile-failed sentinel is 125
README
            [ "$compile_rc" -eq 0 ]
          '';

        mkIcarusRtlInit = { name, runSimulation ? true }:
          pkgs.runCommand name {
            nativeBuildInputs = [ pkgs.iverilog pkgs.coreutils pkgs.gnugrep ];
          } ''
            mkdir -p $out work
            cd work
            iverilog -g2012 -o ypcb_rtl_init.vvp \
              -DNO_TEST_MODEL -DSIM_MODEL \
              -s ypcb_rtl_init_tb \
              -I ${src}/testbench \
              ${src}/testbench/ypcb_icarus/ypcb_rtl_init_tb.sv \
              ${src}/testbench/ddr3.sv \
              ${icarusRtlSources} \
              > $out/iverilog.log 2>&1 || compile_rc=$?
            compile_rc="''${compile_rc:-0}"
            echo "$compile_rc" > $out/iverilog.returncode
            if [ "$compile_rc" -eq 0 ] && [ "${if runSimulation then "1" else "0"}" -eq 1 ]; then
              timeout 120s vvp -n ypcb_rtl_init.vvp > $out/init_trace.log 2>&1 || run_rc=$?
            elif [ "$compile_rc" -eq 0 ]; then
              echo "Icarus elaboration passed; simulation not run by this target" > $out/init_trace.log
              run_rc=0
            else
              echo "iverilog compile failed; vvp not run" > $out/init_trace.log
              run_rc=125
            fi
            run_rc="''${run_rc:-0}"
            echo "$run_rc" > $out/vvp.returncode
            cp ypcb_rtl_init.vvp $out/ 2>/dev/null || true
            if grep -q "INIT_SUCCESS" $out/init_trace.log; then
              sim_status=success
            elif grep -q "INIT_TIMEOUT" $out/init_trace.log; then
              sim_status=timeout
            else
              sim_status=unknown
            fi
            cat > $out/summary.txt <<SUMMARY
stage=rtl-init
micron_sim=1
bist_mode=0
stop_condition=instruction_address_13_and_state_calibrate_non_idle
iverilog_returncode=$compile_rc
vvp_returncode=$run_rc
simulation_status=$sim_status
SUMMARY
            cat > $out/README.md <<README
# YPCB RTL init Icarus result

- stage: rtl-init
- micron_model: testbench/ddr3.sv
- stop condition: instruction_address == 13 and state_calibrate != IDLE
- trace: init_trace.log
- iverilog return code: $compile_rc
- vvp return code: $run_rc
- timeout return code is 124
- compile-failed sentinel is 125
README
            [ "$compile_rc" -eq 0 ]
          '';

        mkIcarusGateBist = { name, gateNetlist, sdf ? null, annotateSdf ? false }:
          pkgs.runCommand name {
            nativeBuildInputs = [ pkgs.iverilog pkgs.coreutils pkgs.yosys ];
          } ''
            mkdir -p $out work
            cp ${gateNetlist}/${ypcb.project}_gate.v work/${ypcb.project}_gate.v
            cp ${src}/testbench/ypcb_sdf/ypcb_sdf_bist_tb.v work/ypcb_sdf_bist_tb.v
            ${lib.optionalString (sdf != null) "cp ${sdf}/${ypcb.project}.sdf work/${ypcb.project}.sdf"}
            cd work
            iverilog -g2012 ${if annotateSdf then "-gspecify -Ttyp" else ""} -o ypcb_sdf_bist.vvp \
              -I ${src}/testbench \
              ${pkgs.yosys}/share/yosys/xilinx/cells_sim.v \
              ${src}/testbench/ypcb_icarus/xilinx_gate_stubs.v \
              ${src}/testbench/ddr3.sv \
              ${ypcb.project}_gate.v \
              ypcb_sdf_bist_tb.v \
              > $out/iverilog.log 2>&1 || compile_rc=$?
            compile_rc="''${compile_rc:-0}"
            echo "$compile_rc" > $out/iverilog.returncode
            cp ${ypcb.project}.sdf $out/ 2>/dev/null || true
            cp ${ypcb.project}_gate.v $out/
            if [ "$compile_rc" -eq 0 ]; then
              timeout 120s vvp -n ypcb_sdf_bist.vvp +fast_init +drive_dqs ${if annotateSdf then "+sdf" else ""} > $out/vvp.log 2>&1 || run_rc=$?
            else
              echo "iverilog compile failed; vvp not run" > $out/vvp.log
              run_rc=125
            fi
            run_rc="''${run_rc:-0}"
            echo "$run_rc" > $out/vvp.returncode
            cat > $out/README.md <<README
# Experimental Icarus gate BIST result

- stage: ${if annotateSdf then "gate-bist-sdf" else "gate-bist-no-sdf"}
- iverilog return code: $compile_rc
- vvp return code: $run_rc
- timeout return code is 124
- compile-failed sentinel is 125
README
          '';

        mkFasm = { name, nextpnrJson }:
          pkgs.runCommand name { nativeBuildInputs = [ pkgs.coreutils ]; } ''
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

        mkCandidate = { suffix, seed ? null, pnrArgs ? "", placer ? null, router ? null, lockFile ? null, yosysJson ? ypcbDdr3YosysJson }:
          let
            pnr = mkNextpnrJson { name = "ypcb-ddr3-nextpnr-json-${suffix}"; inherit seed pnrArgs placer router lockFile yosysJson; };
            fasmDrv = mkFasm { name = "ypcb-ddr3-fasm-${suffix}"; nextpnrJson = pnr; };
            frames = mkFrames { name = "ypcb-ddr3-frames-${suffix}"; inherit fasmDrv; };
            bitstream = mkBitstream { name = "ypcb-ddr3-bitstream-${suffix}"; framesDrv = frames; };
            sdf = mkSdf { name = "ypcb-ddr3-sdf-${suffix}"; inherit seed pnrArgs placer router lockFile yosysJson; };
            gateNetlist = mkGateNetlist { name = "ypcb-ddr3-gate-netlist-${suffix}"; inherit yosysJson; };
            icarusGateBist = mkIcarusGateBist { name = "ypcb-ddr3-icarus-gate-bist-${suffix}"; inherit gateNetlist; };
            icarusSdfBist = mkIcarusGateBist { name = "ypcb-ddr3-icarus-sdf-bist-${suffix}"; inherit gateNetlist sdf; annotateSdf = true; };
          in { inherit pnr fasmDrv frames bitstream sdf gateNetlist icarusGateBist icarusSdfBist; };

        baseline = mkCandidate { suffix = "baseline"; yosysJson = ypcbDdr3DebugYosysJson; };
        prodBaseline = mkCandidate { suffix = "prod-baseline"; yosysJson = ypcbDdr3YosysJson; };
        debugJtag = baseline;
        panopticonBaseline = mkCandidate { suffix = "panopticon-baseline"; pnrArgs = "--no-tmdriv"; yosysJson = ypcbDdr3PanopticonYosysJson; };
        traceScopeBaseline = mkCandidate { suffix = "trace-scope-baseline"; pnrArgs = "--no-tmdriv"; yosysJson = ypcbDdr3TraceScopeYosysJson; };
        resetReleaseLutSeed2Lock = "example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_reset_release_lut_seed2_locks.json";
        seed1ResetReleaseLutSeed2Lock = mkCandidate {
          suffix = "seed-1-reset-release-lut-seed2-lock";
          seed = 1;
          lockFile = resetReleaseLutSeed2Lock;
        };
        reliabilitySeeds = lib.range 1 200;
        seedCandidates = lib.genAttrs (map toString reliabilitySeeds) (seed:
          mkCandidate { suffix = "seed-${seed}"; seed = lib.toInt seed; yosysJson = ypcbDdr3DebugYosysJson; });
        prodSeedCandidates = lib.genAttrs (map toString reliabilitySeeds) (seed:
          mkCandidate { suffix = "prod-seed-${seed}"; seed = lib.toInt seed; yosysJson = ypcbDdr3YosysJson; });
        noTmdrivSeedCandidates = lib.genAttrs (map toString reliabilitySeeds) (seed:
          mkCandidate { suffix = "no-tmdriv-seed-${seed}"; seed = lib.toInt seed; pnrArgs = "--no-tmdriv"; yosysJson = ypcbDdr3DebugYosysJson; });
        panopticonSeedCandidates = lib.genAttrs (map toString reliabilitySeeds) (seed:
          mkCandidate { suffix = "panopticon-seed-${seed}"; seed = lib.toInt seed; pnrArgs = "--no-tmdriv"; yosysJson = ypcbDdr3PanopticonYosysJson; });
        traceScopeSeedCandidates = lib.genAttrs (map toString reliabilitySeeds) (seed:
          mkCandidate { suffix = "trace-scope-seed-${seed}"; seed = lib.toInt seed; pnrArgs = "--no-tmdriv"; yosysJson = ypcbDdr3TraceScopeYosysJson; });
        panopticonSweepCandidates = lib.listToAttrs (map (variant:
          lib.nameValuePair variant.suffix (mkCandidate {
            suffix = variant.suffix;
            pnrArgs = "--no-tmdriv --timing-allow-fail";
            yosysJson = ypcbDdr3PanopticonSweepYosysJsons.${variant.suffix};
          })
        ) ypcbDdr3PanopticonSweepVariants);
        panopticonSweepSeedCandidates = lib.listToAttrs (lib.concatMap (variant:
          map (seed:
            let
              seedString = toString seed;
              suffix = "${variant.suffix}-seed-${seedString}";
            in lib.nameValuePair suffix (mkCandidate {
              inherit suffix seed;
              pnrArgs = "--no-tmdriv --timing-allow-fail";
              yosysJson = ypcbDdr3PanopticonSweepYosysJsons.${variant.suffix};
            })
          ) reliabilitySeeds
        ) ypcbDdr3PanopticonSweepVariants);
        panopticonTraceSeedCandidates = lib.listToAttrs (lib.concatMap (variant:
          map (seed:
            let
              seedString = toString seed;
              suffix = "${variant.suffix}-seed-${seedString}";
            in lib.nameValuePair suffix (mkCandidate {
              inherit suffix seed;
              pnrArgs = "--no-tmdriv";
              yosysJson = ypcbDdr3PanopticonTraceYosysJsons.${variant.suffix};
            })
          ) reliabilitySeeds
        ) ypcbDdr3PanopticonTraceVariants);
        seedBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-seed-${seed}" candidate.bitstream) seedCandidates;
        prodSeedBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-prod-seed-${seed}" candidate.bitstream) prodSeedCandidates;
        noTmdrivSeedBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-no-tmdriv-seed-${seed}" candidate.bitstream) noTmdrivSeedCandidates;
        panopticonSeedBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-panopticon-seed-${seed}" candidate.bitstream) panopticonSeedCandidates;
        traceScopeSeedBitstreams = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-trace-scope-seed-${seed}" candidate.bitstream) traceScopeSeedCandidates;
        seedPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-seed-${seed}" candidate.pnr) seedCandidates;
        prodSeedPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-prod-seed-${seed}" candidate.pnr) prodSeedCandidates;
        noTmdrivSeedPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-no-tmdriv-seed-${seed}" candidate.pnr) noTmdrivSeedCandidates;
        panopticonSeedPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-panopticon-seed-${seed}" candidate.pnr) panopticonSeedCandidates;
        traceScopeSeedPnrs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-trace-scope-seed-${seed}" candidate.pnr) traceScopeSeedCandidates;
        panopticonSweepYosysJsonPackages = lib.mapAttrs' (suffix: yosysJson:
          lib.nameValuePair "ypcb-ddr3-yosys-json-${suffix}" yosysJson) ypcbDdr3PanopticonSweepYosysJsons;
        panopticonTraceYosysJsonPackages = lib.mapAttrs' (suffix: yosysJson:
          lib.nameValuePair "ypcb-ddr3-yosys-json-${suffix}" yosysJson) ypcbDdr3PanopticonTraceYosysJsons;
        panopticonSweepPnrs = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-${suffix}" candidate.pnr) panopticonSweepCandidates;
        panopticonSweepSeedPnrs = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-${suffix}" candidate.pnr) panopticonSweepSeedCandidates;
        panopticonTraceSeedPnrs = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-nextpnr-json-${suffix}" candidate.pnr) panopticonTraceSeedCandidates;
        panopticonSweepFasms = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-${suffix}" candidate.fasmDrv) panopticonSweepCandidates;
        panopticonSweepSeedFasms = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-${suffix}" candidate.fasmDrv) panopticonSweepSeedCandidates;
        panopticonTraceSeedFasms = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-${suffix}" candidate.fasmDrv) panopticonTraceSeedCandidates;
        panopticonSweepFrames = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-frames-${suffix}" candidate.frames) panopticonSweepCandidates;
        panopticonSweepSeedFrames = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-frames-${suffix}" candidate.frames) panopticonSweepSeedCandidates;
        panopticonTraceSeedFrames = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-frames-${suffix}" candidate.frames) panopticonTraceSeedCandidates;
        panopticonSweepBitstreams = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-${suffix}" candidate.bitstream) panopticonSweepCandidates;
        panopticonSweepSeedBitstreams = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-${suffix}" candidate.bitstream) panopticonSweepSeedCandidates;
        panopticonTraceSeedBitstreams = lib.mapAttrs' (suffix: candidate:
          lib.nameValuePair "ypcb-ddr3-bitstream-${suffix}" candidate.bitstream) panopticonTraceSeedCandidates;
        seedFasms = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-fasm-seed-${seed}" candidate.fasmDrv) seedCandidates;
        seedSdfs = lib.mapAttrs' (seed: candidate:
          lib.nameValuePair "ypcb-ddr3-sdf-seed-${seed}" candidate.sdf) seedCandidates;
        ypcbDdr3TopParameterMatrixCsv =
          let
            fields = [
              "index" "suffix" "label" "axis" "controller_clk_period" "ddr3_clk_period"
              "row_bits" "col_bits" "ba_bits" "byte_lanes" "aux_width"
              "wb2_addr_bits" "wb2_data_bits" "micron_sim" "odelay_supported"
              "second_wishbone" "wb_error" "bist_mode" "bist_test_datamask"
              "ecc_enable" "dic" "rtt_nom" "self_refresh" "speed_bin"
              "sdram_capacity" "notes"
            ];
            row = index: variant: lib.concatStringsSep "," [
              (toString index)
              variant.suffix
              variant.label
              variant.axis
              (toString variant.controllerClkPeriod)
              (toString variant.ddr3ClkPeriod)
              (toString variant.rowBits)
              (toString variant.colBits)
              (toString variant.baBits)
              (toString variant.byteLanes)
              (toString variant.auxWidth)
              (toString variant.wb2AddrBits)
              (toString variant.wb2DataBits)
              (toString variant.micronSim)
              (toString variant.odelaySupported)
              (toString variant.secondWishbone)
              (toString variant.wbError)
              (toString variant.bistMode)
              (toString variant.bistTestDatamask)
              (toString variant.eccEnable)
              variant.dic
              variant.rttNom
              variant.selfRefresh
              (toString variant.speedBin)
              (toString variant.sdramCapacity)
              variant.notes
            ];
            rows = lib.imap0 row ypcbDdr3PanopticonSweepVariants;
          in pkgs.writeText "ypcb-ddr3-top-parameter-matrix.csv" ((lib.concatStringsSep "," fields) + "\n" + (lib.concatStringsSep "\n" rows) + "\n");

        mkBoardManifest = { name, variant, candidates, seeds, repeats ? 1 }:
          let
            lines = lib.concatMap (seed:
              map (repeat:
                let
                  seedString = toString seed;
                  repeatString = toString repeat;
                  bitstream = candidates.${seedString}.bitstream;
                in "${variant}-seed-${seedString}-repeat-${repeatString},${seedString},${repeatString},${variant},${bitstream}/${ypcb.project}_openxc7.bit"
              ) (lib.range 1 repeats)
            ) seeds;
            csv = lib.concatStringsSep "\n" ([
              "experiment_id,seed,repeat,variant,bitstream_file"
            ] ++ lines) + "\n";
          in pkgs.writeText name csv;
      in {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ openXc7Shell ];
          packages = [ pkgs.libftdi1 ];
          shellHook = ''
            ${openXc7Shell.shellHook or ""}
            export PRJXRAY_DB_DIR="${patchedPrjxrayDb}"
            export LIBFTDI1_SO="${pkgs.libftdi1}/lib/libftdi1.so"
            export LD_LIBRARY_PATH="${pkgs.libftdi1}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          '';
        };

        checks = {
          icarus-compile = pkgs.runCommand "uberddr3-icarus-compile" {
            nativeBuildInputs = [ pkgs.coreutils pkgs.iverilog ];
          } ''
            cp -R ${src} src
            chmod -R u+w src
            cd src/testbench/icarus_sim
            iverilog -o uberddr3_sim -g2012 -DNO_TEST_MODEL -DSIM_MODEL -s ddr3_dimm_micron_sim -I ../ ../ddr3_dimm_micron_sim.sv ../ddr3.sv ../models/IDELAYCTRL_model.v ../models/IDELAYE2_model.v ../models/IOBUF_DCIEN_model.v ../models/IOBUF_model.v ../models/IOBUFDS_DCIEN_model.v ../models/IOBUFDS_model.v ../models/ISERDESE2_model.v ../models/OBUFDS_model.v ../models/ODELAYE2_model.v ../models/OSERDESE2_model.v ../models/OBUF_model.v ../../rtl/ddr3_top.v ../../rtl/ddr3_controller.v ../../rtl/ddr3_phy.v ../ddr3_module.sv
            mkdir -p $out
            cp uberddr3_sim $out/
            echo Icarus elaboration passed > $out/summary.txt
          '';

          ypcb-rtl-bist-icarus-compile = mkIcarusRtlBist {
            name = "ypcb-ddr3-rtl-bist-icarus-compile";
            runSimulation = false;
          };

          ypcb-rtl-init-icarus = mkIcarusRtlInit {
            name = "ypcb-ddr3-rtl-init-icarus-check";
            runSimulation = true;
          };

          formal-ecc = pkgs.runCommand "uberddr3-formal-ecc" {
            nativeBuildInputs = [ pkgs.sby pkgs.yosys pkgs.boolector pkgs.yices pkgs.coreutils ];
          } ''
            cp -R ${src} src
            chmod -R u+w src
            cd src
            sby -f -d formal-ecc formal/ecc.sby
            mkdir -p "$out"
            cp -R formal-ecc "$out/"
          '';

          formal-ddr3-singleconfig-bmc = pkgs.runCommand "uberddr3-formal-ddr3-singleconfig-bmc" {
            nativeBuildInputs = [ pkgs.sby pkgs.yosys pkgs.boolector pkgs.yices pkgs.gnused pkgs.coreutils ];
          } ''
            cp -R ${src} src
            chmod -R u+w src
            cd src
            sed "s|^mode prove$|mode bmc|" formal/ddr3_singleconfig.sby > ddr3_singleconfig_bmc.sby
            sby -f -d formal-ddr3-singleconfig-bmc ddr3_singleconfig_bmc.sby
            mkdir -p "$out"
            cp -R formal-ddr3-singleconfig-bmc "$out/"
          '';

          verilog-lint = pkgs.runCommand "uberddr3-verilog-lint" {
            nativeBuildInputs = [ pkgs.verilator pkgs.coreutils ];
          } ''
            cp -R ${src} src
            chmod -R u+w src
            cd src
            verilator --lint-only --timing -DSIM_MODEL -DNO_TEST_MODEL --top-module ddr3_top -GAUX_WIDTH=8 -Wall --Wno-fatal -Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL testbench/models/*_model.v rtl/ddr3_controller.v rtl/ddr3_phy.v rtl/ddr3_top.v
            mkdir -p $out
            echo Verilator lint passed > $out/summary.txt
          '';
        };

        packages = {
          formal-ddr3-calib-timeout-ypcb-bmc = pkgs.runCommand "uberddr3-formal-ddr3-calib-timeout-ypcb-bmc" {
            nativeBuildInputs = [ pkgs.sby pkgs.yosys pkgs.boolector pkgs.yices pkgs.coreutils ];
          } ''
            cp -R ${src} src
            chmod -R u+w src
            cd src
            sby -f -d formal-ddr3-calib-timeout-ypcb-bmc formal/ddr3_calib_timeout_ypcb.sby
            mkdir -p "$out"
            cp -R formal-ddr3-calib-timeout-ypcb-bmc "$out/"
          '';

          ypcb-ddr3-yosys-json = ypcbDdr3YosysJson;
          ypcb-ddr3-yosys-json-debug-jtag = ypcbDdr3DebugYosysJson;
          ypcb-ddr3-yosys-json-panopticon = ypcbDdr3PanopticonYosysJson;
          ypcb-ddr3-yosys-json-trace-scope = ypcbDdr3TraceScopeYosysJson;
          ypcb-ddr3-top-parameter-matrix = ypcbDdr3TopParameterMatrixCsv;
          ypcb-ddr3-chipdb = ypcbDdr3Chipdb;
          ypcb-ddr3-nextpnr-json = baseline.pnr;
          ypcb-ddr3-nextpnr-json-baseline = baseline.pnr;
          ypcb-ddr3-nextpnr-json-prod = prodBaseline.pnr;
          ypcb-ddr3-fasm = baseline.fasmDrv;
          ypcb-ddr3-fasm-baseline = baseline.fasmDrv;
          ypcb-ddr3-fasm-prod = prodBaseline.fasmDrv;
          ypcb-ddr3-frames = baseline.frames;
          ypcb-ddr3-frames-baseline = baseline.frames;
          ypcb-ddr3-frames-prod = prodBaseline.frames;
          ypcb-ddr3-bitstream = baseline.bitstream;
          ypcb-ddr3-bitstream-baseline = baseline.bitstream;
          ypcb-ddr3-bitstream-prod = prodBaseline.bitstream;
          ypcb-ddr3-sdf = baseline.sdf;
          ypcb-ddr3-sdf-baseline = baseline.sdf;
          ypcb-ddr3-sdf-prod = prodBaseline.sdf;
          ypcb-ddr3-gate-netlist = baseline.gateNetlist;
          ypcb-ddr3-gate-netlist-baseline = baseline.gateNetlist;
          ypcb-ddr3-gate-netlist-prod = prodBaseline.gateNetlist;
          ypcb-ddr3-rtl-bist-icarus = mkIcarusRtlBist {
            name = "ypcb-ddr3-rtl-bist-icarus";
            runSimulation = true;
          };
          ypcb-ddr3-rtl-init-icarus = mkIcarusRtlInit {
            name = "ypcb-ddr3-rtl-init-icarus";
            runSimulation = true;
          };
          ypcb-ddr3-rtl-init-icarus-compile = mkIcarusRtlInit {
            name = "ypcb-ddr3-rtl-init-icarus-compile";
            runSimulation = false;
          };
          ypcb-ddr3-rtl-bist-icarus-compile = mkIcarusRtlBist {
            name = "ypcb-ddr3-rtl-bist-icarus-compile";
            runSimulation = false;
          };
          ypcb-ddr3-icarus-gate-bist = baseline.icarusGateBist;
          ypcb-ddr3-icarus-gate-bist-baseline = baseline.icarusGateBist;
          ypcb-ddr3-icarus-sdf-bist = baseline.icarusSdfBist;
          ypcb-ddr3-icarus-sdf-bist-baseline = baseline.icarusSdfBist;
          ypcb-ddr3-gate-netlist-seed-1 = seedCandidates."1".gateNetlist;
          ypcb-ddr3-icarus-gate-bist-seed-1 = seedCandidates."1".icarusGateBist;
          ypcb-ddr3-icarus-sdf-bist-seed-1 = seedCandidates."1".icarusSdfBist;
          ypcb-ddr3-gate-netlist-seed-2 = seedCandidates."2".gateNetlist;
          ypcb-ddr3-icarus-gate-bist-seed-2 = seedCandidates."2".icarusGateBist;
          ypcb-ddr3-icarus-sdf-bist-seed-2 = seedCandidates."2".icarusSdfBist;
          ypcb-ddr3-gate-netlist-seed-3 = seedCandidates."3".gateNetlist;
          ypcb-ddr3-icarus-gate-bist-seed-3 = seedCandidates."3".icarusGateBist;
          ypcb-ddr3-icarus-sdf-bist-seed-3 = seedCandidates."3".icarusSdfBist;
          ypcb-ddr3-gate-netlist-seed-6 = seedCandidates."6".gateNetlist;
          ypcb-ddr3-icarus-gate-bist-seed-6 = seedCandidates."6".icarusGateBist;
          ypcb-ddr3-icarus-sdf-bist-seed-6 = seedCandidates."6".icarusSdfBist;
          ypcb-ddr3-nextpnr-json-debug-jtag = debugJtag.pnr;
          ypcb-ddr3-bitstream-debug-jtag = debugJtag.bitstream;
          ypcb-ddr3-nextpnr-json-panopticon = panopticonBaseline.pnr;
          ypcb-ddr3-bitstream-panopticon = panopticonBaseline.bitstream;
          ypcb-ddr3-nextpnr-json-trace-scope = traceScopeBaseline.pnr;
          ypcb-ddr3-bitstream-trace-scope = traceScopeBaseline.bitstream;
          ypcb-ddr3-nextpnr-json-seed-1-reset-release-lut-seed2-lock = seed1ResetReleaseLutSeed2Lock.pnr;
          ypcb-ddr3-fasm-seed-1-reset-release-lut-seed2-lock = seed1ResetReleaseLutSeed2Lock.fasmDrv;
          ypcb-ddr3-bitstream-seed-1-reset-release-lut-seed2-lock = seed1ResetReleaseLutSeed2Lock.bitstream;
          ypcb-ddr3-board-manifest-debug-stage1 = mkBoardManifest {
            name = "ypcb-ddr3-board-manifest-debug-stage1.csv";
            variant = "debug-calib-bist";
            candidates = seedCandidates;
            seeds = lib.range 1 30;
            repeats = 3;
          };
          ypcb-ddr3-board-manifest-debug-heldout = mkBoardManifest {
            name = "ypcb-ddr3-board-manifest-debug-heldout.csv";
            variant = "debug-calib-bist";
            candidates = seedCandidates;
            seeds = lib.range 31 60;
            repeats = 1;
          };
          ypcb-ddr3-board-manifest-panopticon-stage1 = mkBoardManifest {
            name = "ypcb-ddr3-board-manifest-panopticon-stage1.csv";
            variant = "panopticon";
            candidates = panopticonSeedCandidates;
            seeds = lib.range 1 30;
            repeats = 3;
          };
          ypcb-ddr3-board-manifest-panopticon-heldout = mkBoardManifest {
            name = "ypcb-ddr3-board-manifest-panopticon-heldout.csv";
            variant = "panopticon";
            candidates = panopticonSeedCandidates;
            seeds = lib.range 31 60;
            repeats = 3;
          };
          default = baseline.bitstream;
        } // panopticonSweepYosysJsonPackages // panopticonTraceYosysJsonPackages // seedBitstreams // prodSeedBitstreams // noTmdrivSeedBitstreams // panopticonSeedBitstreams // traceScopeSeedBitstreams // seedPnrs // prodSeedPnrs // noTmdrivSeedPnrs // panopticonSeedPnrs // traceScopeSeedPnrs // panopticonSweepPnrs // panopticonSweepSeedPnrs // panopticonTraceSeedPnrs // seedFasms // panopticonSweepFasms // panopticonSweepSeedFasms // panopticonTraceSeedFasms // panopticonSweepFrames // panopticonSweepSeedFrames // panopticonTraceSeedFrames // panopticonSweepBitstreams // panopticonSweepSeedBitstreams // panopticonTraceSeedBitstreams // seedSdfs;
      });
}
