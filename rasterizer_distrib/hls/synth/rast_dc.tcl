# Simple syhthesis script to use FreePDK/45nm libraries
#
# 
#
file mkdir reports
file mkdir netlist

remove_design -all

define_design_lib RAST -path "RAST"

#####################
# Config Variables
#####################
# The clock input signal name.
set CLK  "clk"
# The reset input signal name.
set RST  "rst"

set DRIVER_CELL "INV_X1"
set DR_CELL_OUT "ZN"

set CLK_PERIOD $::env(CLOCK_PERIOD)

#####################
# Path Variables
#####################
set SYN  /cad/synopsys/syn/M-2016.12-SP2/libraries/syn/
set OPENCELL_45 ../../lib/


#####################
# Set Design Library
#####################

# OpenCell 45nm Library
set link_library [list NangateOpenCellLibrary.db dw_foundation.sldb]
set target_library [list NangateOpenCellLibrary.db]

#set link_library { * tcbn45gsbwphvtml.db dw_foundation.sldb}
#set target_library "tcbn45gsbwphvtml.db"

set synthetic_library [list  dw_foundation.sldb]
set dw_lib     $SYN
set sym_lib    $OPENCELL_45
set target_lib $OPENCELL_45

#set tech_file 
#set mw_reference_library 
#set mw_lib_name 
#set max_tlu_file
#set min_tlu_file
#set prs_map_file

set search_path [list ./ ../rtl/  $dw_lib $target_lib $sym_lib ../params/ ]

#set mv_power_net VDD
#set mw_ground_net VSS
#set mw_logic1_net VDD
#set mw_logic0_net VSS
#set mw_power_port VDD
#set mw_ground_port VSS

#create_mw_lib -technology $tech_file \
#              -mw_reference_library $mw_reference_library \
#                                    $mw_lib_name
#open_mw_lib $mw_lib_name 

#report_mw_lib
#set_check_library_options -logic_vs_physical
#check_library

#set_tlu_plus_files -max_tluplus  $max_tlu_file \
#                   -min_tluplus  $min_tlu_file \
#                   -tech2itf_map $prs_map_file

#check_tlu_plus_files

###################
# Read Design
###################

#analyze -library RAST -format sverilog [glob ${RUNDIR}/params/*.sv ${RUNDIR}/rtl/*.v ${RUNDIR}/rtl/*.sv]

#analyze -library RAST -format sverilog [glob ${RUNDIR}/genesis_synth/*.v]
#
#elaborate ${DESIGN_TARGET} -architecture verilog -library RAST
analyze -library RAST -format sverilog {../build/Rasterizer.v1/concat_rtl.v}
elaborate Rasterizer -architecture verilog -library RAST
#read_file {../build/Rasterizer.v1/concat_rtl.v} -autoread -top Rasterizer
current_design Rasterizer

link
#################################
# Define Design Environment 
#################################
# go here

#################################
# Design Rule Constraints
#################################
# go here


##################################
# Design Optimization Constraints
##################################

source ../build/Rasterizer.v1/rtl.v.dc.sdc

##########################################
# Synthesize Design (Optimize for Timing)
##########################################
#set power analysis
#set_power_prediction
set_optimize_registers true -design Rasterizer
compile_ultra -retime -timing_high_effort_script -gate_clock
##########################
# Analyze Design 
##########################
redirect "reports/design_report" { report_design }
check_design
redirect "reports/design_check" {check_design }
#report_constraint -all_violators
#redirect "reports/constraint_report" {report_constraint -all_violators}
report_area 
redirect "reports/area_report" { report_area }
report_power
redirect "reports/power_report" { report_power -analysis_effort hi }
#redirect "reports/power_hier_report" { report_power -hier }
#report_timing -path full -delay max -max_paths 10
#redirect "report/timing_report_max" { report_timing -path full -delay max -max_paths 200 }
#report_timing -path full -delay min -max_paths 10
report_timing
redirect "reports/timing_report_maxsm" { report_timing -significant_digits 4 }
#redirect "reports/timing_report_min" { report_timing -path full -delay min -max_paths 50 }
#report_timing_requirements
#redirect "reports/timing_requirements_report" { report_timing_requirements }
report_qor
redirect "reports/qor_report" { report_qor }
check_error
redirect "reports/error_checking_report" { check_error }




###################################
# Save the Design DataBase
###################################
write_sdf -version 2.1 "netlist/sdf_rasterizer"
write -hierarchy -format verilog -output "netlist/rast.gv"
write -format verilog -hier -o "netlist/rast.psv"
write -format ddc -hierarchy -output "rast.mapped.ddc"

exit 





