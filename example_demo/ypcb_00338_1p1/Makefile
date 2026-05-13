PROJECT = ypcb_00338_1p1_ddr3
BIST_PROJECT = ypcb_00338_1p1_uberddr3_bist
ROWSTREAM_PROJECT = ypcb_00338_1p1_uberddr3_rowstream_loader
FAMILY = kintex7
PART = xc7k480tffg1156-2
DBPART = $(shell echo ${PART} | sed -e 's/-[0-9].*//g')

TOP_MODULE = ${PROJECT}
TOP_VERILOG = ${PROJECT}.v
XDC = ${PROJECT}.xdc
BIST_XDC = ${BIST_PROJECT}.xdc
ROWSTREAM_XDC = ${ROWSTREAM_PROJECT}.xdc
CHIPDB ?= .
REPO_ROOT := ../..
V40_BEL_LOCKS ?= ${REPO_ROOT}/artifacts/task6/baselines/uberddr3-rowstream-loader-v40-physical-stability/known-good-packed-bel-locks.json
V40_PRE_PLACE_BEL_LOCKS ?= v40-phy-pre-place-bel-locks.py
DDR3_CLOCK_CONSTRAINTS ?= ${REPO_ROOT}/scripts/task6/nextpnr_ypcb_uberddr3_clock_constraints.py

ADDITIONAL_SOURCES = \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv \
	clk_wiz.v

PYPY3 ?= pypy3
SYNTH_XILINX_FLAGS ?= -flatten -abc9 -arch xc7
PNR_ARGS ?= --seed 16 --freq 25
PNR_DEBUG ?=
SEED ?= 3
FREQ ?= 25
ROWSTREAM_ROUTED_JSON ?= ../../artifacts/manual-seed/seed${SEED}/nextpnr-routed.seed${SEED}.freq${FREQ}.json
ROWSTREAM_BITSTREAM_OUT ?= ../../artifacts/manual-seed/seed${SEED}/ypcb_00338_1p1_uberddr3_rowstream_loader_seed${SEED}_freq${FREQ}.bit
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

.PHONY: rowstream-v40-json
rowstream-v40-json: PNR_PRE_PLACE = --pre-place ${V40_PRE_PLACE_BEL_LOCKS}
rowstream-v40-json:
	@mkdir -p ../../artifacts/manual-seed/seed${SEED}
	@mkdir -p $(dir ${ROWSTREAM_ROUTED_JSON})
	@mkdir -p $(dir ${ROWSTREAM_BITSTREAM_OUT})
	$(MAKE) clean
	$(MAKE) rowstream-v40-locked \
		SYNTH_XILINX_FLAGS="-flatten -arch xc7" \
		PNR_ARGS="--seed ${SEED} --freq ${FREQ}" \
		PNR_DEBUG="--write ${ROWSTREAM_ROUTED_JSON}"
	cp ${ROWSTREAM_PROJECT}_openxc7.bit ${ROWSTREAM_BITSTREAM_OUT}
	@printf 'Generated rowstream bitstream: %s\nGenerated routed json: %s\n' ${ROWSTREAM_BITSTREAM_OUT} ${ROWSTREAM_ROUTED_JSON}

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
	yosys -p "synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${TOP_MODULE}; delete t:\$$scopeinfo; write_json $@" $< ${ADDITIONAL_SOURCES}

${BIST_PROJECT}.json: ${BIST_SOURCES} Makefile
	yosys -p "synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${BIST_PROJECT}; delete t:\$$scopeinfo; write_json $@" ${BIST_SOURCES}

${ROWSTREAM_PROJECT}.json: ${ROWSTREAM_SOURCES} Makefile
	yosys -p "synth_xilinx ${SYNTH_XILINX_FLAGS} ${SYNTH_OPTS} -top ${ROWSTREAM_PROJECT}; delete t:\$$scopeinfo; write_json $@" ${ROWSTREAM_SOURCES}

${V40_PRE_PLACE_BEL_LOCKS}: ${V40_BEL_LOCKS} ${REPO_ROOT}/scripts/task6/generate_nextpnr_pre_place_bel_locks.py
	python3 ${REPO_ROOT}/scripts/task6/generate_nextpnr_pre_place_bel_locks.py \
		--locks-json ${V40_BEL_LOCKS} \
		--scope ddr3_clocks \
		--scope uberddr3_phy \
		--ypcb-wrapper-remap \
		--skip-cell clk100_90_bufg \
		--out-py $@

${CHIPDB}/${DBPART}.bin:
	${PYPY3} ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
	bbasm -l ${DBPART}.bba $@
	rm -f ${DBPART}.bba

${PROJECT}.fasm: ${PROJECT}.json ${CHIPDB}/${DBPART}.bin ${XDC} ypcb_vref.features
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${XDC} --json ${PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	cat ypcb_vref.features >> $@

${BIST_XDC}: ${XDC}
	sed '/led/d' $< > $@

${ROWSTREAM_XDC}: ${XDC}
	sed '/led/d' $< > $@

${BIST_PROJECT}.fasm: ${BIST_PROJECT}.json ${CHIPDB}/${DBPART}.bin ${BIST_XDC} ypcb_vref.features ${V40_PRE_PLACE_BEL_LOCKS}
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${BIST_XDC} --json ${BIST_PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	cat ypcb_vref.features >> $@

${ROWSTREAM_PROJECT}.fasm: ${ROWSTREAM_PROJECT}.json ${CHIPDB}/${DBPART}.bin ${ROWSTREAM_XDC} ypcb_vref.features ${V40_PRE_PLACE_BEL_LOCKS}
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${ROWSTREAM_XDC} --json ${ROWSTREAM_PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_PRE_PLACE} ${PNR_ARGS} ${PNR_DEBUG}
	cat ypcb_vref.features >> $@

${PROJECT}.frames: ${PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${BIST_PROJECT}.frames: ${BIST_PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${ROWSTREAM_PROJECT}.frames: ${ROWSTREAM_PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${PROJECT}_openxc7.bit: ${PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

${BIST_PROJECT}_openxc7.bit: ${BIST_PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

${ROWSTREAM_PROJECT}_openxc7.bit: ${ROWSTREAM_PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

.PHONY: clean
clean:
	rm -f ${PROJECT}_openxc7.bit ${PROJECT}.frames ${PROJECT}.fasm ${PROJECT}.json \
		${BIST_PROJECT}_openxc7.bit ${BIST_PROJECT}.frames ${BIST_PROJECT}.fasm ${BIST_PROJECT}.json \
		${ROWSTREAM_PROJECT}_openxc7.bit ${ROWSTREAM_PROJECT}.frames ${ROWSTREAM_PROJECT}.fasm ${ROWSTREAM_PROJECT}.json \
		${BIST_XDC} ${ROWSTREAM_XDC} ${DBPART}.bin ${DBPART}.bba ${V40_PRE_PLACE_BEL_LOCKS}
