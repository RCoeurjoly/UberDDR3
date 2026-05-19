PROJECT = ypcb_00338_1p1_ddr3
FAMILY = kintex7
PART = xc7k480tffg1156-2
DBPART = $(shell echo ${PART} | sed -e 's/-[0-9].*//g')
CHIPDB ?= .
CHIPDB_BIN := ${CHIPDB}/${DBPART}.bin
ifeq ($(suffix ${CHIPDB}),.bin)
CHIPDB_BIN := ${CHIPDB}
endif

REPO_ROOT := ../..
YPCB_UBERDDR3_CLOCK_PROFILE ?= openxc7-333
YOSYS_DEFINES ?=
ifeq (${YPCB_UBERDDR3_CLOCK_PROFILE},openxc7-333)
override YOSYS_DEFINES += -DYPCB_UBERDDR3_CLOCK_PROFILE_OPENXC7_333
export YPCB_UBERDDR3_CONTROLLER_CLK_MHZ := 83.333333
export YPCB_UBERDDR3_DDR3_CLK_MHZ := 333.333333
export YPCB_UBERDDR3_REF_CLK_MHZ := 200
endif

SOURCES = \
	${PROJECT}.v \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv \
	clk_wiz.v

SYNTH_XILINX_FLAGS ?= -flatten -abc9 -arch xc7
PNR_ARGS ?= --seed 3
PNR_DEBUG ?=
PNR_PRE_PACK ?= --pre-pack nextpnr_clock_constraints.py

.PHONY: openxc7 clean
openxc7: ${PROJECT}_openxc7.bit

${PROJECT}.json: ${SOURCES} Makefile
	yosys ${YOSYS_DEFINES} -p "synth_xilinx ${SYNTH_XILINX_FLAGS} -top ${PROJECT}; delete t:\$$scopeinfo; write_json $@" ${SOURCES}

${CHIPDB_BIN}:
	pypy3 ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
	bbasm -l ${DBPART}.bba $@
	rm -f ${DBPART}.bba

${PROJECT}.fasm: ${PROJECT}.json ${PROJECT}.xdc ${CHIPDB_BIN}
	nextpnr-xilinx --chipdb ${CHIPDB_BIN} --xdc ${PROJECT}.xdc --json ${PROJECT}.json --fasm $@ ${PNR_PRE_PACK} ${PNR_ARGS} ${PNR_DEBUG}

${PROJECT}.frames: ${PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${PROJECT}_openxc7.bit: ${PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

clean:
	rm -f ${PROJECT}_openxc7.bit ${PROJECT}.frames ${PROJECT}.fasm ${PROJECT}.json ${DBPART}.bin ${DBPART}.bba nextpnr-routed.json
