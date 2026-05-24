PROJECT = ypcb_00338_1p1_ddr3
FAMILY = kintex7
PART = xc7k480tffg1156-2
CHIPDB  = ${KINTEX7_CHIPDB}
ADDITIONAL_SOURCES = ../../rtl/ddr3_controller.v ../../rtl/ddr3_phy.v ../../rtl/ddr3_top.v clk_wiz.v

NEXTPNR_XILINX_DIR ?= /snap/openxc7/current/opt/nextpnr-xilinx
NEXTPNR_XILINX_PYTHON_DIR ?= ${NEXTPNR_XILINX_DIR}/python
PRJXRAY_DB_DIR ?= ${NEXTPNR_XILINX_DIR}/external/prjxray-db

DBPART = $(shell echo ${PART} | sed -e 's/-[0-9]//g')
SPEEDGRADE = $(shell echo ${PART} | sed -e 's/.*\-\([0-9]\)/\1/g')

CHIPDB ?= ./
ifeq ($(CHIPDB),)
CHIPDB = ./
endif

PYPY3 ?= pypy3

TOP ?= ${PROJECT}
TOP_MODULE ?= ${TOP}
TOP_VERILOG ?= ${TOP}.v

PNR_DEBUG ?= # --verbose --debug
PNR_ARGS ?=
PNR_FREQ_MHZ ?= 83.333
BEL_LOCKS_JSON ?= constraints/ypcb_00338_1p1_ddr3_bel_locks.json
BEL_LOCKS_PRE_PLACE ?= ${PROJECT}_bel_locks_pre_place.py
BEL_LOCKS_ALLOW_MISSING ?= 0
UNLOCKED_PLACED_JSON ?= ${PROJECT}.placed.unlocked.json
PNR_PRE_PLACE_ARGS = $(if $(wildcard ${BEL_LOCKS_JSON}),--pre-place ${BEL_LOCKS_PRE_PLACE},)

JTAG_LINK ?= -c digilent_hs3

XDC ?= ${PROJECT}.xdc

.PHONY: openxc7
openxc7: ${PROJECT}_openxc7.bit

.PHONY: program
program: ${PROJECT}_openxc7.bit
	openFPGALoader ${JTAG_LINK} --bitstream $<

${PROJECT}.json: ${TOP_VERILOG} ${ADDITIONAL_SOURCES} Makefile
	yosys -p "read_verilog $< ${ADDITIONAL_SOURCES}; synth_xilinx -flatten -abc9 ${SYNTH_OPTS} -arch xc7 -top ${TOP_MODULE}; write_json ${PROJECT}.json"

# The chip database only needs to be generated once
# that is why we don't clean it with make clean
${CHIPDB}/${DBPART}.bin:
	${PYPY3} ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
	bbasm -l ${DBPART}.bba ${CHIPDB}/${DBPART}.bin
	rm -f ${DBPART}.bba

${BEL_LOCKS_PRE_PLACE}: ${BEL_LOCKS_JSON} scripts/generate_nextpnr_pre_place_bel_locks.py
	python3 scripts/generate_nextpnr_pre_place_bel_locks.py --locks-json ${BEL_LOCKS_JSON} --out-py $@ $(if $(filter 1,$(BEL_LOCKS_ALLOW_MISSING)),--allow-missing,)

${PROJECT}.fasm: ${PROJECT}.json ${CHIPDB}/${DBPART}.bin ${XDC} $(if $(wildcard ${BEL_LOCKS_JSON}),${BEL_LOCKS_PRE_PLACE},)
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${XDC} --json ${PROJECT}.json --fasm $@ --freq ${PNR_FREQ_MHZ} ${PNR_PRE_PLACE_ARGS} ${PNR_ARGS} ${PNR_DEBUG}

${PROJECT}.placed.json: ${PROJECT}.json ${CHIPDB}/${DBPART}.bin ${XDC} $(if $(wildcard ${BEL_LOCKS_JSON}),${BEL_LOCKS_PRE_PLACE},)
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${XDC} --json ${PROJECT}.json --write $@ --freq ${PNR_FREQ_MHZ} ${PNR_PRE_PLACE_ARGS} ${PNR_ARGS} ${PNR_DEBUG}

${UNLOCKED_PLACED_JSON}: ${PROJECT}.json ${CHIPDB}/${DBPART}.bin ${XDC}
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${XDC} --json ${PROJECT}.json --write $@ --freq ${PNR_FREQ_MHZ} ${PNR_ARGS} ${PNR_DEBUG}

.PHONY: extract-bel-locks
extract-bel-locks: ${UNLOCKED_PLACED_JSON}
	python3 scripts/extract_nextpnr_bel_locks.py \
		--placed-json ${UNLOCKED_PLACED_JSON} \
		--out-json ${BEL_LOCKS_JSON} \
		--include-cell-prefix ddr3_phy=ddr3_top_inst.ddr3_phy_inst. \
		--include-cell-prefix ddr3_controller=ddr3_top_inst.ddr3_controller_inst. \
		--include-typed-attr-substring ddr3_controller=SLICE_FFX:src:../../rtl/ddr3_controller.v

${PROJECT}.frames: ${PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${PROJECT}_openxc7.bit: ${PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@


.PHONY: clean
clean:
	rm -f *.bit
	rm -f *.frames
	rm -f *.fasm
	rm -f *.json
	rm -f *.bin
	rm -f *.bba
	rm -f *_bel_locks_pre_place.py
