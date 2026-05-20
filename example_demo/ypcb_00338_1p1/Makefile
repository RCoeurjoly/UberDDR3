PROJECT = ypcb_00338_1p1_ddr3
FAMILY = kintex7
PART = xc7k480tffg1156-2
CHIPDB  = ${KINTEX7_CHIPDB}
ADDITIONAL_SOURCES = ../../rtl/ddr3_controller.v  ../../rtl/ddr3_phy.v  ../../rtl/ddr3_top.v  uart_rx.v  uart_tx.v clk_wiz.v jtag_debug_bscan.v

#############################################################################################
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
PNR_FREQ_MHZ ?= 83.333

JTAG_LINK ?= -c digilent_hs2

XDC ?= ${PROJECT}.xdc

.PHONY: openxc7
openxc7: ${PROJECT}_openxc7.bit

.PHONY: openxc7_calib_only openxc7_short_bist openxc7_calib_only_1lane openxc7_calib_only_2lanes openxc7_tiny_bist_1lane openxc7_tiny_bist_2lanes openxc7_calib_only_odelay openxc7_calib_only_odelay_2lanes
openxc7_calib_only:
	$(MAKE) openxc7 PROJECT=${PROJECT}_calib_only TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_CALIB_ONLY"

openxc7_short_bist:
	$(MAKE) openxc7 PROJECT=${PROJECT}_short_bist TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_SHORT_BIST"

openxc7_calib_only_1lane:
	$(MAKE) openxc7 PROJECT=${PROJECT}_calib_only_1lane TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_CALIB_ONLY -D YPCB_ONE_LANE"

openxc7_calib_only_2lanes:
	$(MAKE) openxc7 PROJECT=${PROJECT}_calib_only_2lanes TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_CALIB_ONLY -D YPCB_TWO_LANES"

openxc7_tiny_bist_1lane:
	$(MAKE) openxc7 PROJECT=${PROJECT}_tiny_bist_1lane TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_TINY_BIST -D YPCB_ONE_LANE"

openxc7_tiny_bist_2lanes:
	$(MAKE) openxc7 PROJECT=${PROJECT}_tiny_bist_2lanes TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_TINY_BIST -D YPCB_TWO_LANES"

openxc7_calib_only_odelay:
	$(MAKE) openxc7 PROJECT=${PROJECT}_calib_only_odelay TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_CALIB_ONLY -D YPCB_ODELAY_SUPPORTED"

openxc7_calib_only_odelay_2lanes:
	$(MAKE) openxc7 PROJECT=${PROJECT}_calib_only_odelay_2lanes TOP_MODULE=${TOP_MODULE} TOP_VERILOG=${TOP_VERILOG} XDC=${XDC} VERILOG_DEFINES="-D YPCB_CALIB_ONLY -D YPCB_ODELAY_SUPPORTED -D YPCB_TWO_LANES"

.PHONY: program
program: ${PROJECT}_openxc7.bit
	openFPGALoader ${JTAG_LINK} --bitstream $<

${PROJECT}.json: ${TOP_VERILOG} ${ADDITIONAL_SOURCES} Makefile
	yosys -p "read_verilog ${VERILOG_DEFINES} $< ${ADDITIONAL_SOURCES}; synth_xilinx -flatten -abc9 ${SYNTH_OPTS} -arch xc7 -top ${TOP_MODULE}; delete t:\$$scopeinfo; write_json ${PROJECT}.json"

# The chip database only needs to be generated once
# that is why we don't clean it with make clean
${CHIPDB}/${DBPART}.bin:
	${PYPY3} ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
	bbasm -l ${DBPART}.bba ${CHIPDB}/${DBPART}.bin
	rm -f ${DBPART}.bba

${PROJECT}.fasm: ${PROJECT}.json ${CHIPDB}/${DBPART}.bin ${XDC}
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${XDC} --json ${PROJECT}.json --fasm $@ ${PNR_ARGS} --freq ${PNR_FREQ_MHZ} ${PNR_DEBUG}

${PROJECT}.frames: ${PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${PROJECT}_openxc7.bit: ${PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@


#############################################################################################
# SPDX-License-Identifier: MIT
# Generated from https://github.com/FPGAOL-CE/caas-wizard
#
BUILDDIR := ${CURDIR}/build
VIVADO_SUFFIX ?= vivado
VIVADO_VERILOG_DEFINES ?=
VIVADO_TCL := ${BUILDDIR}/${PROJECT}_${VIVADO_SUFFIX}.tcl
VIVADO_BIT := ${BUILDDIR}/${PROJECT}_${VIVADO_SUFFIX}.bit

LOGFILE := ${BUILDDIR}/${PROJECT}_${VIVADO_SUFFIX}.log

# Build design
.PHONY: vivado vivado_calib_only vivado_short_bist vivado_calib_only_2lanes
vivado: ${VIVADO_BIT}

vivado_calib_only:
	$(MAKE) vivado VIVADO_SUFFIX=vivado_calib_only VIVADO_VERILOG_DEFINES="YPCB_CALIB_ONLY"

vivado_short_bist:
	$(MAKE) vivado VIVADO_SUFFIX=vivado_short_bist VIVADO_VERILOG_DEFINES="YPCB_SHORT_BIST"

vivado_calib_only_2lanes:
	$(MAKE) vivado VIVADO_SUFFIX=vivado_calib_only_2lanes VIVADO_VERILOG_DEFINES="YPCB_CALIB_ONLY YPCB_TWO_LANES"

${BUILDDIR}:
	mkdir -m 777 -p ${BUILDDIR} && chown -R nobody ${BUILDDIR} | true

.ONESHELL:
${VIVADO_TCL}: ${BUILDDIR}
	cat << EOF > $@
	# vivado.tcl generated for FPGAOL-CE/caas-wizard
	# can be launched from any directory
	cd ${BUILDDIR}
	create_project -part ${PART} -force v_proj
	set_property target_language Verilog [current_project]
	cd ..
	if { "${VIVADO_VERILOG_DEFINES}" ne "" } { set_property verilog_define {${VIVADO_VERILOG_DEFINES}} [current_fileset] }
	read_verilog [glob ${PROJECT}.v ${ADDITIONAL_SOURCES}]
	read_xdc [glob  $(wildcard ${PROJECT}.xdc) ]
	cd build
	synth_design -top ${PROJECT}
	opt_design
	place_design
	phys_opt_design
	route_design
	write_checkpoint -force ${PROJECT}_${VIVADO_SUFFIX}_routed.dcp
	report_utilization -file ${PROJECT}_${VIVADO_SUFFIX}_util.rpt
	report_timing_summary -file ${PROJECT}_${VIVADO_SUFFIX}_timing.rpt
	report_clock_utilization -file ${PROJECT}_${VIVADO_SUFFIX}_clock_util.rpt
	report_io -file ${PROJECT}_${VIVADO_SUFFIX}_io.rpt
	set ddr_cells [get_cells -hierarchical -filter {REF_NAME =~ ISERDESE2 || REF_NAME =~ OSERDESE2 || REF_NAME =~ IDELAYE2 || REF_NAME =~ ODELAYE2 || REF_NAME =~ IDELAYCTRL || REF_NAME =~ IOBUF || REF_NAME =~ IOBUFDS || REF_NAME =~ PLLE2_ADV || REF_NAME =~ BUFG}]
	set fp [open ${PROJECT}_${VIVADO_SUFFIX}_ddr_cells.tsv w]
	puts \$$fp "name\tref_name\tsite\tbel\tloc"
	foreach c [lsort \$$ddr_cells] {
	    puts \$$fp [format "%s\t%s\t%s\t%s\t%s" \$$c [get_property REF_NAME \$$c] [get_property SITE \$$c] [get_property BEL \$$c] [get_property LOC \$$c]]
	}
	close \$$fp
	write_bitstream -verbose -force ${PROJECT}_${VIVADO_SUFFIX}.bit
	# report_utilization -file util.rpt
	# report_timing_summary -file timing.rpt
	EOF

${VIVADO_BIT}: ${VIVADO_TCL}
	cd ${BUILDDIR} && vivado -mode batch -source $< > ${LOGFILE} 2>&1

.PHONY: program_vivado
program_vivado:
	openFPGALoader ${JTAG_LINK} --bitstream ${VIVADO_BIT}


#############################################################################################

.PHONY: clean
clean:
	rm -f *.bit
	rm -f *.frames
	rm -f *.fasm
	rm -f *.json
	rm -f *.bin
	rm -f *.bba
	rm -rf ${BUILDDIR}
