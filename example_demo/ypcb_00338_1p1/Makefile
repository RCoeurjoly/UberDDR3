PROJECT = ypcb_00338_1p1_ddr3
FAMILY = kintex7
PART = xc7k480tffg1156-2
DBPART = $(shell echo ${PART} | sed -e 's/-[0-9].*//g')

TOP_MODULE = ${PROJECT}
TOP_VERILOG = ${PROJECT}.v
XDC = ${PROJECT}.xdc
CHIPDB ?= .

ADDITIONAL_SOURCES = \
	../../rtl/ddr3_controller.v \
	../../rtl/ddr3_phy.v \
	../../rtl/ddr3_top.v \
	../../rtl/ecc/ecc_dec.sv \
	../../rtl/ecc/ecc_enc.sv \
	clk_wiz.v

PYPY3 ?= pypy3
PNR_ARGS ?= --seed 16 --freq 25
PNR_DEBUG ?=
JTAG_LINK ?= -c digilent_hs2

.PHONY: openxc7
openxc7: ${PROJECT}_openxc7.bit

.PHONY: program
program: ${PROJECT}_openxc7.bit
	openFPGALoader ${JTAG_LINK} --bitstream $<

${PROJECT}.json: ${TOP_VERILOG} ${ADDITIONAL_SOURCES} Makefile
	yosys -p "synth_xilinx -flatten -abc9 ${SYNTH_OPTS} -arch xc7 -top ${TOP_MODULE}; delete t:\$$scopeinfo; write_json $@" $< ${ADDITIONAL_SOURCES}

${CHIPDB}/${DBPART}.bin:
	${PYPY3} ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
	bbasm -l ${DBPART}.bba $@
	rm -f ${DBPART}.bba

${PROJECT}.fasm: ${PROJECT}.json ${CHIPDB}/${DBPART}.bin ${XDC} ypcb_vref.features
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${XDC} --json ${PROJECT}.json --fasm $@ ${PNR_ARGS} ${PNR_DEBUG}
	cat ypcb_vref.features >> $@

${PROJECT}.frames: ${PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${PROJECT}_openxc7.bit: ${PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

.PHONY: clean
clean:
	rm -f ${PROJECT}_openxc7.bit ${PROJECT}.frames ${PROJECT}.fasm ${PROJECT}.json ${DBPART}.bin ${DBPART}.bba
