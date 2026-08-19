set REPORTS_DIR Reports
set OUTPUTS_DIR Outputs
if {![file exists $OUTPUTS_DIR]} {file mkdir $OUTPUTS_DIR}
if {![file exists $REPORTS_DIR]} {file mkdir $REPORTS_DIR}

#@gui_start
gui_set_pref_value -category {SelectByNamePalette} -key {ObjectType} -value {LeafCells}
read_file -format verilog {/home/MS_115/acc01/remote/band_pass_filter/02_hdl/00_rtl/adder/adder_tree_15.v \
                            /home/MS_115/acc01/remote/band_pass_filter/02_hdl/00_rtl/adder/adder_tree_17.v \
                            /home/MS_115/acc01/remote/band_pass_filter/02_hdl/00_rtl/hpf_rtl.v \
                            /home/MS_115/acc01/remote/band_pass_filter/02_hdl/00_rtl/lpf_rtl.v \
                            /home/MS_115/acc01/remote/band_pass_filter/02_hdl/00_rtl/top_rtl.v}
current_design top_rtl
set_operating_conditions -min_library fast -min fast  -max_library slow -max slow
set_wire_load_model -name tsmc18_wl10 -library slow
create_clock -name clk -period 5 [get_ports clk]
set_dont_touch_network  [get_clocks clk ]
set_fix_hold  [get_clocks clk]
set_ideal_network [get_ports clk]
set_clock_uncertainty 0.5 [get_clocks clk]
set_input_transition   0.5     [all_inputs]
set_clock_transition   0.1     [all_clocks]
set_input_delay -max 2 -clock clk  [get_port *_in]
set_clock_latency  0.5 [get_clocks clk]
set high_fanout_net_threshold 0
uniquify

compile

report_timing >> $REPORTS_DIR/Report.timing.rpt
report_power >> $REPORTS_DIR/Report.power.rpt
report_area >> $REPORTS_DIR/Report.area.rpt
report_reference >> $REPORTS_DIR/Report.Ref.rpt

remove_unconnected_ports -blast_buses [get_cells -hierarchical *]

change_names -hierarchy -rule verilog

write -format ddc -hierarchy -output $OUTPUTS_DIR/test_syn.ddc
write -hierarchy -format verilog -output $OUTPUTS_DIR/test_syn.v
write_sdf -version 2.1 -context verilog -load_delay net $OUTPUTS_DIR/test_syn.sdf 
exit
