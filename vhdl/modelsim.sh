#!/bin/bash

# Settings...
export MODULE=top_level
export ALTERA=/opt/altera/11.0sp1/quartus
export SIGNALS="\
	uut.hSync_in \
	uut.vSync_in \
	uut.rgbi_in \
	--- \
	disp16 \
	uut.hCount16 \
	uut.writeEn0 \
	uut.writeEn1 \
	uut.lineToggle \
	uut.vSync_s16 \
	uut.hSyncStart \
	uut.vSyncStart \
	uut.state \
	--- \
	disp25 \
	uut.hCount25 \
	--- \
	uut.hSync_out \
	uut.vSync_out \
	uut.rgbi_out \
"

# Build the Altera megafunction library if necessary
if [ ! -e altera_mf ]; then
	vlib altera_mf
	vmap altera_mf altera_mf
	vcom -2008 -work altera_mf ${ALTERA}/eda/sim_lib/altera_mf_components.vhd
	vcom -2008 -work altera_mf ${ALTERA}/eda/sim_lib/altera_mf.vhd
fi

# Compile all our code
rm -rf work
vlib work
if [ ! -e hex_util.vhdl ]; then
	wget -q https://raw.github.com/makestuff/sim_utils/master/vhdl/hex_util.vhdl
fi
vcom -2008 -work work hex_util.vhdl
vcom -2008 -work work clk_gen/clk_gen.vhd
vcom -2008 -work work dpram/dpram.vhd
vcom -2008 -work work ${MODULE}.vhdl
vcom -2008 -work work ${MODULE}_tb.vhdl

# Create startup files and vsim command-line
rm -f startup.tcl startup.do
echo "vcd file results.vcd" > startup.do
export VOPTARGS="+acc"
for i in ${SIGNALS}; do
	if [ "${i}" = "---" ]; then
		echo "gtkwave::/Edit/Insert_Blank" >> startup.tcl
	else
		export VOPTARGS="${VOPTARGS}+${MODULE}_tb/${i//.//}"
		echo "gtkwave::addSignalsFromList ${i}" >> startup.tcl
		echo "vcd add ${i//.//}" >> startup.do
	fi
done
echo 'for { set i 0 } { $i <= [ gtkwave::getVisibleNumTraces ] } { incr i } { gtkwave::setTraceHighlightFromIndex $i off }' >> startup.tcl
echo 'gtkwave::setLeftJustifySigs on' >> startup.tcl
echo 'gtkwave::setZoomFactor -18' >> startup.tcl
echo 'gtkwave::setMarker 120ns' >> startup.tcl
echo 'run 260us' >> startup.do
echo 'quit -f' >> startup.do

# Run simulation
echo vsim ${MODULE}_tb -c -t ps -do startup.do -voptargs="$VOPTARGS"
vsim ${MODULE}_tb -c -t ps -do startup.do -voptargs="$VOPTARGS"

# Show results
gtkwave -T startup.tcl results.vcd
