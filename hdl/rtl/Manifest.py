files = ["ddr3_ctrl.vhd",
         "ddr3_ctrl_wb.vhd",
         "ddr3_ctrl_wrapper.vhd",
         "ddr3_ctrl_pkg.vhd"]

modules = {"local" : ["../spec/ip_cores/ddr3_ctrl_bank3_32b_32b/user_design/rtl",
                      "../spec/ip_cores/ddr3_ctrl_bank3_64b_32b/user_design/rtl",
                      "../svec/ip_cores/ddr3_ctrl_bank4_32b_32b/user_design/rtl",
                      "../svec/ip_cores/ddr3_ctrl_bank4_64b_32b/user_design/rtl",
                      "../svec/ip_cores/ddr3_ctrl_bank5_32b_32b/user_design/rtl",
                      "../svec/ip_cores/ddr3_ctrl_bank5_64b_32b/user_design/rtl"]}
