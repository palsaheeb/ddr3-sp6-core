files = ["ddr3_ctrl.vhd",
         "ddr3_ctrl_wb.vhd",
         "ddr3_ctrl_wrapper.vhd",
         "ddr3_ctrl_wrapper_pkg.vhd",
         "ddr3_ctrl_pkg.vhd"]

local = ["../common/ip_cores/rtl"]

try:

    for ctrl in ctrls:

        if ctrl == "bank3_32b_32b":
            local.append("../spec/ip_cores/ddr3_ctrl_spec_bank3_32b_32b/user_design/rtl")

        else if ctrl == "bank3_64b_32b":
            local.append("../spec/ip_cores/ddr3_ctrl_spec_bank3_64b_32b/user_design/rtl")

        else if ctrl == "bank4_32b_32b":
            local.append("../svec/ip_cores/ddr3_ctrl_svec_bank4_32b_32b/user_design/rtl")

        else if ctrl == "bank4_64b_32b":
            local.append("../svec/ip_cores/ddr3_ctrl_svec_bank4_64b_32b/user_design/rtl")

        else if ctrl == "bank5_32b_32b":
            local.append("../svec/ip_cores/ddr3_ctrl_svec_bank5_32b_32b/user_design/rtl")

        else if ctrl == "bank5_64b_32b":
            local.append("../svec/ip_cores/ddr3_ctrl_svec_bank5_64b_32b/user_design/rtl")

        else if ctrl == "bank1_32b_32b":
            local.append("../vfc/ip_cores/ddr3_ctrl_vfc_bank1_32b_32b/user_design/rtl")

        else if ctrl == "bank1_64b_32b":
            local.append("../vfc/ip_cores/ddr3_ctrl_vfc_bank1_64b_32b/user_design/rtl")

        else:
            print("[ERROR]:DDR3: The controller type is not recognnised!")
            print("              It must be one of: bank1_32b_32b, bank1_64b_32b, bank3_32b_32b, bank3_64b_32b, bank4_32b_32b, bank4_64b_32b, bank5_32b_32b, bank5_64b_32b.")

except NameError:
    print("[ERROR]:DDR3: The variable ctrls MUST be defined in the top Manifest!")


modules = {"local" : local}
