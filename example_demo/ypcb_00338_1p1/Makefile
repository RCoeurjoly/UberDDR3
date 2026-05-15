PROJECT = ypcb_00338_1p1_ddr3
BIST_PROJECT = ypcb_00338_1p1_uberddr3_bist
ROWSTREAM_PROJECT = ypcb_00338_1p1_uberddr3_rowstream_loader
ROWSTREAM_FULLBEAT_PROJECT = ypcb_00338_1p1_uberddr3_rowstream_fullbeat
CALIB_PROJECT = ypcb_00338_1p1_uberddr3_calib_only
FAMILY = kintex7
PART = xc7k480tffg1156-2
DBPART = $(shell echo ${PART} | sed -e 's/-[0-9].*//g')

TOP_MODULE = ${PROJECT}
TOP_VERILOG = ${PROJECT}.v
XDC = ${PROJECT}.xdc
BIST_XDC = ${BIST_PROJECT}.xdc
ROWSTREAM_XDC = ${ROWSTREAM_PROJECT}.xdc
ROWSTREAM_FULLBEAT_XDC = ${ROWSTREAM_FULLBEAT_PROJECT}.xdc
CALIB_XDC = ${CALIB_PROJECT}.xdc
CHIPDB ?= .
CHIPDB_BIN := ${CHIPDB}/${DBPART}.bin
ifeq ($(suffix ${CHIPDB}),.bin)
CHIPDB_BIN := ${CHIPDB}
endif
REPO_ROOT := ../..
V40_BEL_LOCKS ?= ${REPO_ROOT}/artifacts/task6/baselines/uberddr3-rowstream-loader-v40-physical-stability/known-good-packed-bel-locks.json
V40_PRE_PLACE_BEL_LOCKS ?= v40-phy-pre-place-bel-locks.py
GENERATED_CALIB_PRE_PLACE_BEL_LOCKS ?= v40-calib-phy-pre-place-bel-locks.py
CALIB_PRE_PLACE_BEL_LOCKS ?= ${GENERATED_CALIB_PRE_PLACE_BEL_LOCKS}
ROWSTREAM_PRE_PLACE_DEPS ?= ${V40_PRE_PLACE_BEL_LOCKS}
ROWSTREAM_FULLBEAT_PRE_PLACE_DEPS ?= ${CALIB_PRE_PLACE_BEL_LOCKS}
CALIB_PRE_PLACE_DEPS ?= ${CALIB_PRE_PLACE_BEL_LOCKS}
DDR3_CLOCK_CONSTRAINTS ?= ${REPO_ROOT}/scripts/task6/nextpnr_ypcb_uberddr3_clock_constraints.py
APPEND_YPCB_VREF ?= 1

ADDITIONAL_SOURCES = \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv \
	clk_wiz.v

PYPY3 ?= pypy3
YOSYS_DEFINES ?=
YPCB_CALIB_COMMAND_WB_ENABLE ?= 0
YPCB_CALIB_COMMAND_JTAG_ENABLE ?= 0
YPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE ?= 0
YPCB_CALIB_COMMAND_FULLBEAT_ENABLE ?= 1
YPCB_CALIB_COMMAND_READBACK_ENABLE ?= 1
YPCB_CALIB_DEBUG_WB_DATA_ENABLE ?= 1
YPCB_CALIB_ISOLATE_WB_UNTIL_CALIB_DONE ?= 0
CALIB_YOSYS_DEFINES ?= \
	-DYPCB_CALIB_COMMAND_WB_ENABLE=${YPCB_CALIB_COMMAND_WB_ENABLE} \
	-DYPCB_CALIB_COMMAND_JTAG_ENABLE=${YPCB_CALIB_COMMAND_JTAG_ENABLE} \
	-DYPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE=${YPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE} \
	-DYPCB_CALIB_COMMAND_FULLBEAT_ENABLE=${YPCB_CALIB_COMMAND_FULLBEAT_ENABLE} \
	-DYPCB_CALIB_COMMAND_READBACK_ENABLE=${YPCB_CALIB_COMMAND_READBACK_ENABLE} \
	-DYPCB_CALIB_DEBUG_WB_DATA_ENABLE=${YPCB_CALIB_DEBUG_WB_DATA_ENABLE} \
	-DYPCB_CALIB_ISOLATE_WB_UNTIL_CALIB_DONE=${YPCB_CALIB_ISOLATE_WB_UNTIL_CALIB_DONE}
SYNTH_XILINX_FLAGS ?= -flatten -abc9 -arch xc7
ROWSTREAM_SYNTH_PRELUDE ?=
PNR_ARGS ?= --seed 16 --freq 25
PNR_DEBUG ?=
SEED ?= 3
FREQ ?= 25
ROWSTREAM_ROUTED_JSON ?= ../../artifacts/manual-seed/seed${SEED}/nextpnr-routed.seed${SEED}.freq${FREQ}.json
ROWSTREAM_BITSTREAM_OUT ?= ../../artifacts/manual-seed/seed${SEED}/ypcb_00338_1p1_uberddr3_rowstream_loader_seed${SEED}_freq${FREQ}.bit
ROWSTREAM_FULLBEAT_ROUTED_JSON ?= ../../artifacts/manual-seed/fullbeat-seed${SEED}/nextpnr-routed.seed${SEED}.freq${FREQ}.json
ROWSTREAM_FULLBEAT_BITSTREAM_OUT ?= ../../artifacts/manual-seed/fullbeat-seed${SEED}/ypcb_00338_1p1_uberddr3_rowstream_fullbeat_seed${SEED}_freq${FREQ}.bit
CALIB_ROUTED_JSON ?= ../../artifacts/manual-seed/calib-seed${SEED}/nextpnr-routed.seed${SEED}.freq${FREQ}.json
CALIB_BITSTREAM_OUT ?= ../../artifacts/manual-seed/calib-seed${SEED}/ypcb_00338_1p1_uberddr3_calib_only_seed${SEED}_freq${FREQ}.bit
ROWSTREAM_SYNTH_JSON ?=
CALIB_SYNTH_JSON ?=
ifeq (${FREQ},0)
DEFAULT_PNR_ARGS = --seed ${SEED}
else
DEFAULT_PNR_ARGS = --seed ${SEED} --freq ${FREQ}
endif
DEFAULT_PNR_DEBUG = --write ${ROWSTREAM_ROUTED_JSON}
ifneq ($(origin PNR_ARGS), command line)
PNR_ARGS = $(DEFAULT_PNR_ARGS)
endif
ifneq ($(origin PNR_DEBUG), command line)
PNR_DEBUG = $(DEFAULT_PNR_DEBUG)
endif
ifeq ($(origin PNR_DEBUG), command line)
ifeq ($(word 1,${PNR_DEBUG}),--write)
ifneq ($(origin ROWSTREAM_ROUTED_JSON), command line)
ROWSTREAM_ROUTED_JSON = $(word 2,${PNR_DEBUG})
endif
endif
endif
ROWSTREAM_ROUTED_JSON_ABS = $(abspath ${ROWSTREAM_ROUTED_JSON})
ROWSTREAM_BITSTREAM_OUT_ABS = $(abspath ${ROWSTREAM_BITSTREAM_OUT})
ROWSTREAM_FULLBEAT_ROUTED_JSON_ABS = $(abspath ${ROWSTREAM_FULLBEAT_ROUTED_JSON})
ROWSTREAM_FULLBEAT_BITSTREAM_OUT_ABS = $(abspath ${ROWSTREAM_FULLBEAT_BITSTREAM_OUT})
CALIB_ROUTED_JSON_ABS = $(abspath ${CALIB_ROUTED_JSON})
CALIB_BITSTREAM_OUT_ABS = $(abspath ${CALIB_BITSTREAM_OUT})
PNR_PRE_PACK ?= --pre-pack ${DDR3_CLOCK_CONSTRAINTS}
PNR_PRE_PLACE ?=
JTAG_LINK ?= -c digilent_hs2
FTDI_SERIAL ?= 210299BF3824
OPENOCD_ADAPTER_SPEED ?= 6000

BIST_SOURCES = \
	${BIST_PROJECT}.v \
	../../fpga/rtl/ypcb_uberddr3_bist_top.sv \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv

ROWSTREAM_SOURCES = \
	${ROWSTREAM_PROJECT}.v \
	../../fpga/rtl/task6_ypcb_uberddr3_bist_rowstream_loader_top.sv \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv

ROWSTREAM_FULLBEAT_SOURCES = \
	${ROWSTREAM_FULLBEAT_PROJECT}.v \
	../../fpga/rtl/task6_ypcb_uberddr3_rowstream_loader_top.sv \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv

CALIB_SOURCES = \
	${CALIB_PROJECT}.v \
	../../fpga/rtl/task6_ypcb_uberddr3_calib_only_top.sv \
	../../fpga/rtl/task6_uberddr3_rowstream_command_port.sv \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv

.PHONY: openxc7
openxc7: ${PROJECT}_openxc7.bit

.PHONY: bist
bist: ${BIST_PROJECT}_openxc7.bit

.PHONY: bist-v40-locked
bist-v40-locked: PNR_PRE_PLACE = --pre-place ${V40_PRE_PLACE_BEL_LOCKS}
bist-v40-locked: ${BIST_PROJECT}_openxc7.bit

.PHONY: rowstream-v40-locked
rowstream-v40-locked: PNR_PRE_PLACE = --pre-place ${V40_PRE_PLACE_BEL_LOCKS}
rowstream-v40-locked: ${ROWSTREAM_PROJECT}_openxc7.bit

.PHONY: rowstream-fullbeat-v40-locked
rowstream-fullbeat-v40-locked: PNR_PRE_PLACE = --pre-place ${CALIB_PRE_PLACE_BEL_LOCKS}
rowstream-fullbeat-v40-locked: ${ROWSTREAM_FULLBEAT_PROJECT}_openxc7.bit

.PHONY: calib-v40-locked
calib-v40-locked: PNR_PRE_PLACE = --pre-place ${CALIB_PRE_PLACE_BEL_LOCKS}
calib-v40-locked: ${CALIB_PROJECT}_openxc7.bit

.PHONY: rowstream-v40-json
rowstream-v40-json: PNR_PRE_PLACE = --pre-place ${V40_PRE_PLACE_BEL_LOCKS}
rowstream-v40-json:
	@mkdir -p ../../artifacts/manual-seed/seed${SEED}
	@mkdir -p $(dir ${ROWSTREAM_ROUTED_JSON_ABS})
	@mkdir -p $(dir ${ROWSTREAM_BITSTREAM_OUT_ABS})
	$(MAKE) clean-rowstream-pnr
	@printf 'rowstream-v40-json: seed=%s freq=%s chipdb=%s pnr_args=%s routed_json=%s bit_out=%s\n' \
		"${SEED}" "${FREQ}" "${CHIPDB}" "${PNR_ARGS}" "${ROWSTREAM_ROUTED_JSON}" "${ROWSTREAM_BITSTREAM_OUT}"
	$(MAKE) rowstream-v40-locked \
		SYNTH_XILINX_FLAGS="-flatten -arch xc7" \
		SEED="${SEED}" \
		FREQ="${FREQ}" \
		ROWSTREAM_ROUTED_JSON="${ROWSTREAM_ROUTED_JSON_ABS}" \
		ROWSTREAM_BITSTREAM_OUT="${ROWSTREAM_BITSTREAM_OUT_ABS}" \
		PNR_ARGS="$(PNR_ARGS)" \
		PNR_DEBUG="$(PNR_DEBUG)"
	@mkdir -p $(dir ${ROWSTREAM_ROUTED_JSON_ABS})
	@if [ ! -f ${ROWSTREAM_ROUTED_JSON_ABS} ]; then \
		echo "ERROR: expected routed json ${ROWSTREAM_ROUTED_JSON_ABS} not created"; \
		exit 1; \
	fi
	cp ${ROWSTREAM_PROJECT}_openxc7.bit ${ROWSTREAM_BITSTREAM_OUT_ABS}
	@printf 'Generated rowstream bitstream: %s\nGenerated routed json: %s\n' ${ROWSTREAM_BITSTREAM_OUT_ABS} ${ROWSTREAM_ROUTED_JSON_ABS}

.PHONY: rowstream-fullbeat-v40-json
rowstream-fullbeat-v40-json: PNR_PRE_PLACE = --pre-place ${CALIB_PRE_PLACE_BEL_LOCKS}
rowstream-fullbeat-v40-json:
	@mkdir -p $(dir ${ROWSTREAM_FULLBEAT_ROUTED_JSON_ABS})
	@mkdir -p $(dir ${ROWSTREAM_FULLBEAT_BITSTREAM_OUT_ABS})
	$(MAKE) clean-rowstream-fullbeat-pnr
	@printf 'rowstream-fullbeat-v40-json: seed=%s freq=%s chipdb=%s pnr_args=%s routed_json=%s bit_out=%s\n' \
		"${SEED}" "${FREQ}" "${CHIPDB}" "${PNR_ARGS}" "${ROWSTREAM_FULLBEAT_ROUTED_JSON}" "${ROWSTREAM_FULLBEAT_BITSTREAM_OUT}"
	$(MAKE) rowstream-fullbeat-v40-locked \
		SYNTH_XILINX_FLAGS="-flatten -arch xc7" \
		SEED="${SEED}" \
		FREQ="${FREQ}" \
		ROWSTREAM_FULLBEAT_ROUTED_JSON="${ROWSTREAM_FULLBEAT_ROUTED_JSON_ABS}" \
		ROWSTREAM_FULLBEAT_BITSTREAM_OUT="${ROWSTREAM_FULLBEAT_BITSTREAM_OUT_ABS}" \
		PNR_ARGS="$(PNR_ARGS)" \
		PNR_DEBUG="--write ${ROWSTREAM_FULLBEAT_ROUTED_JSON_ABS}"
	@if [ ! -f ${ROWSTREAM_FULLBEAT_ROUTED_JSON_ABS} ]; then \
		echo "ERROR: expected routed json ${ROWSTREAM_FULLBEAT_ROUTED_JSON_ABS} not created"; \
		exit 1; \
	fi
	cp ${ROWSTREAM_FULLBEAT_PROJECT}_openxc7.bit ${ROWSTREAM_FULLBEAT_BITSTREAM_OUT_ABS}
	@printf 'Generated fullbeat rowstream bitstream: %s\nGenerated routed json: %s\n' ${ROWSTREAM_FULLBEAT_BITSTREAM_OUT_ABS} ${ROWSTREAM_FULLBEAT_ROUTED_JSON_ABS}

.PHONY: calib-v40-json
calib-v40-json: PNR_PRE_PLACE = --pre-place ${CALIB_PRE_PLACE_BEL_LOCKS}
calib-v40-json:
	@mkdir -p $(dir ${CALIB_ROUTED_JSON_ABS})
	@mkdir -p $(dir ${CALIB_BITSTREAM_OUT_ABS})
	rm -f ${CALIB_PROJECT}_openxc7.bit ${CALIB_PROJECT}.frames ${CALIB_PROJECT}.fasm ${CALIB_XDC}
	@printf 'calib-v40-json: seed=%s freq=%s chipdb=%s pnr_args=%s routed_json=%s bit_out=%s\n' \
		"${SEED}" "${FREQ}" "${CHIPDB}" "${PNR_ARGS}" "${CALIB_ROUTED_JSON}" "${CALIB_BITSTREAM_OUT}"
	$(MAKE) calib-v40-locked \
		SYNTH_XILINX_FLAGS="-flatten -arch xc7" \
		SEED="${SEED}" \
		FREQ="${FREQ}" \
		YPCB_CALIB_COMMAND_WB_ENABLE="${YPCB_CALIB_COMMAND_WB_ENABLE}" \
		YPCB_CALIB_COMMAND_JTAG_ENABLE="${YPCB_CALIB_COMMAND_JTAG_ENABLE}" \
		YPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE="${YPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE}" \
		YPCB_CALIB_COMMAND_FULLBEAT_ENABLE="${YPCB_CALIB_COMMAND_FULLBEAT_ENABLE}" \
		YPCB_CALIB_COMMAND_READBACK_ENABLE="${YPCB_CALIB_COMMAND_READBACK_ENABLE}" \
		YPCB_CALIB_DEBUG_WB_DATA_ENABLE="${YPCB_CALIB_DEBUG_WB_DATA_ENABLE}" \
		YPCB_CALIB_ISOLATE_WB_UNTIL_CALIB_DONE="${YPCB_CALIB_ISOLATE_WB_UNTIL_CALIB_DONE}" \
		CALIB_ROUTED_JSON="${CALIB_ROUTED_JSON_ABS}" \
		CALIB_BITSTREAM_OUT="${CALIB_BITSTREAM_OUT_ABS}" \
		PNR_ARGS="$(PNR_ARGS)" \
		PNR_DEBUG="--write ${CALIB_ROUTED_JSON_ABS}"
	@if [ ! -f ${CALIB_ROUTED_JSON_ABS} ]; then \
		echo "ERROR: expected routed json ${CALIB_ROUTED_JSON_ABS} not created"; \
		exit 1; \
	fi
	cp ${CALIB_PROJECT}_openxc7.bit ${CALIB_BITSTREAM_OUT_ABS}
	@printf 'Generated calibration bitstream: %s\nGenerated routed json: %s\n' ${CALIB_BITSTREAM_OUT_ABS} ${CALIB_ROUTED_JSON_ABS}

.PHONY: clean-rowstream-pnr
clean-rowstream-pnr:
	rm -f ${ROWSTREAM_PROJECT}_openxc7.bit ${ROWSTREAM_PROJECT}.frames ${ROWSTREAM_PROJECT}.fasm \
		${ROWSTREAM_XDC}

.PHONY: clean-rowstream-fullbeat-pnr
clean-rowstream-fullbeat-pnr:
	rm -f ${ROWSTREAM_FULLBEAT_PROJECT}_openxc7.bit ${ROWSTREAM_FULLBEAT_PROJECT}.frames ${ROWSTREAM_FULLBEAT_PROJECT}.fasm \
		${ROWSTREAM_FULLBEAT_XDC}

.PHONY: clean-calib-pnr
clean-calib-pnr:
	rm -f ${CALIB_PROJECT}_openxc7.bit ${CALIB_PROJECT}.frames ${CALIB_PROJECT}.fasm \
		${CALIB_XDC}

.PHONY: rowstream-v40-json-pnr-only
rowstream-v40-json-pnr-only:
	@if [ -z "${ROWSTREAM_SYNTH_JSON}" ]; then \
		echo "ERROR: ROWSTREAM_SYNTH_JSON is required for rowstream-v40-json-pnr-only"; \
		exit 1; \
	fi
	@mkdir -p ../../artifacts/manual-seed/seed${SEED}
	@mkdir -p $(dir ${ROWSTREAM_ROUTED_JSON_ABS})
	@mkdir -p $(dir ${ROWSTREAM_BITSTREAM_OUT_ABS})
	$(MAKE) clean-rowstream-pnr
	cp ${ROWSTREAM_SYNTH_JSON} ${ROWSTREAM_PROJECT}.json
	touch ${ROWSTREAM_PROJECT}.json
	@printf 'rowstream-v40-json-pnr-only: seed=%s freq=%s chipdb=%s synth_json=%s pnr_args=%s routed_json=%s bit_out=%s\n' \
		"${SEED}" "${FREQ}" "${CHIPDB}" "${ROWSTREAM_SYNTH_JSON}" "${PNR_ARGS}" "${ROWSTREAM_ROUTED_JSON}" "${ROWSTREAM_BITSTREAM_OUT}"
	$(MAKE) ${ROWSTREAM_PROJECT}_openxc7.bit \
		SEED="${SEED}" \
		FREQ="${FREQ}" \
		ROWSTREAM_ROUTED_JSON="${ROWSTREAM_ROUTED_JSON_ABS}" \
		ROWSTREAM_BITSTREAM_OUT="${ROWSTREAM_BITSTREAM_OUT_ABS}" \
		ROWSTREAM_PRE_PLACE_DEPS="" \
		PNR_PRE_PLACE="$(PNR_PRE_PLACE)" \
		PNR_ARGS="$(PNR_ARGS)" \
		PNR_DEBUG="$(PNR_DEBUG)"
	@if [ ! -f ${ROWSTREAM_ROUTED_JSON_ABS} ]; then \
		echo "ERROR: expected routed json ${ROWSTREAM_ROUTED_JSON_ABS} not created"; \
		exit 1; \
	fi
	cp ${ROWSTREAM_PROJECT}_openxc7.bit ${ROWSTREAM_BITSTREAM_OUT_ABS}
	@printf 'Generated rowstream bitstream: %s\nGenerated routed json: %s\n' ${ROWSTREAM_BITSTREAM_OUT_ABS} ${ROWSTREAM_ROUTED_JSON_ABS}

.PHONY: calib-v40-json-pnr-only
calib-v40-json-pnr-only: PNR_PRE_PLACE = --pre-place ${CALIB_PRE_PLACE_BEL_LOCKS}
calib-v40-json-pnr-only:
	@if [ -z "${CALIB_SYNTH_JSON}" ]; then \
		echo "ERROR: CALIB_SYNTH_JSON is required for calib-v40-json-pnr-only"; \
		exit 1; \
	fi
	@mkdir -p $(dir ${CALIB_ROUTED_JSON_ABS})
	@mkdir -p $(dir ${CALIB_BITSTREAM_OUT_ABS})
	$(MAKE) clean-calib-pnr
	cp ${CALIB_SYNTH_JSON} ${CALIB_PROJECT}.json
	touch ${CALIB_PROJECT}.json
	@printf 'calib-v40-json-pnr-only: seed=%s freq=%s chipdb=%s synth_json=%s pnr_args=%s routed_json=%s bit_out=%s\n' \
		"${SEED}" "${FREQ}" "${CHIPDB}" "${CALIB_SYNTH_JSON}" "${PNR_ARGS}" "${CALIB_ROUTED_JSON}" "${CALIB_BITSTREAM_OUT}"
	$(MAKE) ${CALIB_PROJECT}_openxc7.bit \
		SEED="${SEED}" \
		FREQ="${FREQ}" \
		CALIB_ROUTED_JSON="${CALIB_ROUTED_JSON_ABS}" \
		CALIB_BITSTREAM_OUT="${CALIB_BITSTREAM_OUT_ABS}" \
		PNR_PRE_PLACE="$(PNR_PRE_PLACE)" \
		PNR_ARGS="$(PNR_ARGS)" \
		PNR_DEBUG="--write ${CALIB_ROUTED_JSON_ABS}"
	@if [ ! -f ${CALIB_ROUTED_JSON_ABS} ]; then \
		echo "ERROR: expected routed json ${CALIB_ROUTED_JSON_ABS} not created"; \
		exit 1; \
	fi
	cp ${CALIB_PROJECT}_openxc7.bit ${CALIB_BITSTREAM_OUT_ABS}
	@printf 'Generated calibration bitstream: %s\nGenerated routed json: %s\n' ${CALIB_BITSTREAM_OUT_ABS} ${CALIB_ROUTED_JSON_ABS}

.PHONY: program
program: ${PROJECT}_openxc7.bit
	openFPGALoader ${JTAG_LINK} --bitstream $<

.PHONY: program-bist-openocd
program-bist-openocd: ${BIST_PROJECT}_openxc7.bit
	openocd -f interface/ftdi/digilent_jtag_hs3.cfg \
		-c "adapter serial ${FTDI_SERIAL}" \
		-f cpld/xilinx-xc7.cfg \
		-c "adapter speed ${OPENOCD_ADAPTER_SPEED}" \
		-c "init" \
		-c "pld load 0 $<" \
		-c "exit"

.PHONY: hil-lowbyte-stream
hil-lowbyte-stream: ${BIST_PROJECT}_openxc7.bit
	${MAKE} program-bist-openocd
	cd ${REPO_ROOT} && python3 scripts/task6/validate_uberddr3_lowbyte_stream.py \
		--serial ${FTDI_SERIAL} \
		--expected-version 32 \
		--windows 16 \
		--json-out artifacts/task6/ypcb-uberddr3-lowbyte-stream-latest.json

.PHONY: hil-lowbyte-stream-v40-locked
hil-lowbyte-stream-v40-locked: PNR_PRE_PLACE = --pre-place ${V40_PRE_PLACE_BEL_LOCKS}
hil-lowbyte-stream-v40-locked: ${BIST_PROJECT}_openxc7.bit
	${MAKE} program-bist-openocd
	cd ${REPO_ROOT} && python3 scripts/task6/validate_uberddr3_lowbyte_stream.py \
		--serial ${FTDI_SERIAL} \
		--expected-version 32 \
		--windows 16 \
		--json-out artifacts/task6/ypcb-uberddr3-lowbyte-stream-v40-locked-latest.json

.PHONY: hil-smoke
hil-smoke: ${BIST_PROJECT}_openxc7.bit
	cd ${REPO_ROOT} && python3 scripts/task6/task6_ddr3_experiment_runner.py \
		--label ypcb-uberddr3-bist-smoke \
		--variant make-bist-openocd \
		--bitstream example_demo/ypcb_00338_1p1/${BIST_PROJECT}_openxc7.bit \
		--programmer openocd \
		--ftdi-serial ${FTDI_SERIAL}

.PHONY: hil-smoke-v40-locked
hil-smoke-v40-locked:
	${MAKE} clean
	${MAKE} bist-v40-locked
	cd ${REPO_ROOT} && python3 scripts/task6/task6_ddr3_experiment_runner.py \
		--label ypcb-uberddr3-bist-v40-locked \
		--variant make-bist-v40-locked-openocd \
		--build-attr "" \
		--make-dir example_demo/ypcb_00338_1p1 \
		--make-target bist-v40-locked \
		--bitstream example_demo/ypcb_00338_1p1/${BIST_PROJECT}_openxc7.bit \
		--programmer openocd \
		--ftdi-serial ${FTDI_SERIAL}

${PROJECT}.json: ${TOP_VERILOG} ${ADDITIONAL_SOURCES} Makefile
	yosys ${YOSYS_DEFINES} -p "synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${TOP_MODULE}; delete t:\$$scopeinfo; write_json $@" $< ${ADDITIONAL_SOURCES}

${BIST_PROJECT}.json: ${BIST_SOURCES} Makefile
	yosys ${YOSYS_DEFINES} -p "synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${BIST_PROJECT}; delete t:\$$scopeinfo; write_json $@" ${BIST_SOURCES}

${ROWSTREAM_PROJECT}.json: ${ROWSTREAM_SOURCES} Makefile
	yosys ${YOSYS_DEFINES} -p "${ROWSTREAM_SYNTH_PRELUDE} synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${ROWSTREAM_PROJECT}; delete t:\$$scopeinfo; write_json $@" ${ROWSTREAM_SOURCES}

${ROWSTREAM_FULLBEAT_PROJECT}.json: ${ROWSTREAM_FULLBEAT_SOURCES} Makefile
	yosys ${YOSYS_DEFINES} -p "synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${ROWSTREAM_FULLBEAT_PROJECT}; delete t:\$$scopeinfo; write_json $@" ${ROWSTREAM_FULLBEAT_SOURCES}

${CALIB_PROJECT}.json: ${CALIB_SOURCES} Makefile
	yosys ${YOSYS_DEFINES} ${CALIB_YOSYS_DEFINES} -p "synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${CALIB_PROJECT}; delete t:\$$scopeinfo; write_json $@" ${CALIB_SOURCES}

${V40_PRE_PLACE_BEL_LOCKS}: ${V40_BEL_LOCKS} ${REPO_ROOT}/scripts/task6/generate_nextpnr_pre_place_bel_locks.py
	python3 ${REPO_ROOT}/scripts/task6/generate_nextpnr_pre_place_bel_locks.py \
		--locks-json ${V40_BEL_LOCKS} \
		--scope ddr3_clocks \
		--scope uberddr3_phy \
		--ypcb-wrapper-remap \
		--skip-cell clk100_90_bufg \
		--out-py $@

${GENERATED_CALIB_PRE_PLACE_BEL_LOCKS}: ${V40_PRE_PLACE_BEL_LOCKS}
	sed 's/bist_top/calib_top/g' $< > $@

${CHIPDB_BIN}:
	${PYPY3} ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
	bbasm -l ${DBPART}.bba $@
	rm -f ${DBPART}.bba

${PROJECT}.fasm: ${PROJECT}.json ${CHIPDB_BIN} ${XDC} ypcb_vref.features
	nextpnr-xilinx --chipdb ${CHIPDB_BIN} --xdc ${XDC} --json ${PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	@if [ "${APPEND_YPCB_VREF}" = "1" ]; then cat ypcb_vref.features >> $@; else echo "Skipping ypcb_vref.features append"; fi

${BIST_XDC}: ${XDC}
	sed '/led/d' $< > $@

${ROWSTREAM_XDC}: ${XDC}
	sed '/led/d' $< > $@

${ROWSTREAM_FULLBEAT_XDC}: ${XDC}
	sed '/led/d' $< > $@

${CALIB_XDC}: ${XDC}
	sed '/led/d' $< > $@

${BIST_PROJECT}.fasm: ${BIST_PROJECT}.json ${CHIPDB_BIN} ${BIST_XDC} ypcb_vref.features ${V40_PRE_PLACE_BEL_LOCKS}
	nextpnr-xilinx --chipdb ${CHIPDB_BIN} --xdc ${BIST_XDC} --json ${BIST_PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	@if [ "${APPEND_YPCB_VREF}" = "1" ]; then cat ypcb_vref.features >> $@; else echo "Skipping ypcb_vref.features append"; fi

${ROWSTREAM_PROJECT}.fasm: ${ROWSTREAM_PROJECT}.json ${CHIPDB_BIN} ${ROWSTREAM_XDC} ypcb_vref.features ${ROWSTREAM_PRE_PLACE_DEPS}
	nextpnr-xilinx --chipdb ${CHIPDB_BIN} --xdc ${ROWSTREAM_XDC} --json ${ROWSTREAM_PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	@if [ "${APPEND_YPCB_VREF}" = "1" ]; then cat ypcb_vref.features >> $@; else echo "Skipping ypcb_vref.features append"; fi

${ROWSTREAM_FULLBEAT_PROJECT}.fasm: ${ROWSTREAM_FULLBEAT_PROJECT}.json ${CHIPDB_BIN} ${ROWSTREAM_FULLBEAT_XDC} ypcb_vref.features ${ROWSTREAM_FULLBEAT_PRE_PLACE_DEPS}
	nextpnr-xilinx --chipdb ${CHIPDB_BIN} --xdc ${ROWSTREAM_FULLBEAT_XDC} --json ${ROWSTREAM_FULLBEAT_PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	@if [ "${APPEND_YPCB_VREF}" = "1" ]; then cat ypcb_vref.features >> $@; else echo "Skipping ypcb_vref.features append"; fi

${CALIB_PROJECT}.fasm: ${CALIB_PROJECT}.json ${CHIPDB_BIN} ${CALIB_XDC} ypcb_vref.features ${CALIB_PRE_PLACE_DEPS}
	nextpnr-xilinx --chipdb ${CHIPDB_BIN} --xdc ${CALIB_XDC} --json ${CALIB_PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	@if [ "${APPEND_YPCB_VREF}" = "1" ]; then cat ypcb_vref.features >> $@; else echo "Skipping ypcb_vref.features append"; fi

${PROJECT}.frames: ${PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${BIST_PROJECT}.frames: ${BIST_PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${ROWSTREAM_PROJECT}.frames: ${ROWSTREAM_PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${ROWSTREAM_FULLBEAT_PROJECT}.frames: ${ROWSTREAM_FULLBEAT_PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${CALIB_PROJECT}.frames: ${CALIB_PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${PROJECT}_openxc7.bit: ${PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

${BIST_PROJECT}_openxc7.bit: ${BIST_PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

${ROWSTREAM_PROJECT}_openxc7.bit: ${ROWSTREAM_PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

${ROWSTREAM_FULLBEAT_PROJECT}_openxc7.bit: ${ROWSTREAM_FULLBEAT_PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

${CALIB_PROJECT}_openxc7.bit: ${CALIB_PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

.PHONY: clean
clean:
	rm -f ${PROJECT}_openxc7.bit ${PROJECT}.frames ${PROJECT}.fasm ${PROJECT}.json \
		${BIST_PROJECT}_openxc7.bit ${BIST_PROJECT}.frames ${BIST_PROJECT}.fasm ${BIST_PROJECT}.json \
		${ROWSTREAM_PROJECT}_openxc7.bit ${ROWSTREAM_PROJECT}.frames ${ROWSTREAM_PROJECT}.fasm ${ROWSTREAM_PROJECT}.json \
		${ROWSTREAM_FULLBEAT_PROJECT}_openxc7.bit ${ROWSTREAM_FULLBEAT_PROJECT}.frames ${ROWSTREAM_FULLBEAT_PROJECT}.fasm ${ROWSTREAM_FULLBEAT_PROJECT}.json \
		${CALIB_PROJECT}_openxc7.bit ${CALIB_PROJECT}.frames ${CALIB_PROJECT}.fasm ${CALIB_PROJECT}.json \
		${BIST_XDC} ${ROWSTREAM_XDC} ${ROWSTREAM_FULLBEAT_XDC} ${CALIB_XDC} ${DBPART}.bin ${DBPART}.bba ${V40_PRE_PLACE_BEL_LOCKS} ${GENERATED_CALIB_PRE_PLACE_BEL_LOCKS}
