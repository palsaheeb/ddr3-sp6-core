files = ["ddr3_ctrl.vhd",
         "ddr3_ctrl_wb.vhd",
         "ddr3_ctrl_wrapper.vhd",
         "ddr3_ctrl_wrapper_pkg.vhd",
         "ddr3_ctrl_pkg.vhd"]

modules = {"local" : []}

try:

    # go through each one of the recognized memory controllers, adding them to the list of local
    # modules and removing them from the top Manifest list of controllers

    if "bank3_32b_32b" in ctrls:
        modules["local"].append("../spec/ip_cores/ddr3_ctrl_spec_bank3_32b_32b/user_design/rtl")
        ctrls.remove("bank3_32b_32b")

        if "bank3_64b_32b" in ctrls:
        modules["local"].append("../spec/ip_cores/ddr3_ctrl_spec_bank3_64b_32b/user_design/rtl")
        ctrls.remove("bank3_64b_32b")

    if "bank4_32b_32b" in ctrls:
        modules["local"].append("../svec/ip_cores/ddr3_ctrl_svec_bank4_32b_32b/user_design/rtl")
        ctrls.remove("bank4_32b_32b")

    if "bank4_64b_32b" in ctrls:
        modules["local"].append("../svec/ip_cores/ddr3_ctrl_svec_bank4_64b_32b/user_design/rtl")
        ctrls.remove("bank4_64b_32b")

    if "bank5_32b_32b" in ctrls:
        modules["local"].append("../svec/ip_cores/ddr3_ctrl_svec_bank5_32b_32b/user_design/rtl")
        ctrls.remove("bank5_32b_32b")

    if "bank5_64b_32b" in ctrls:
        modules["local"].append("../svec/ip_cores/ddr3_ctrl_svec_bank5_64b_32b/user_design/rtl")
        ctrls.remove("bank5_64b_32b")

    if "bank1_32b_32b" in ctrls:
        modules["local"].append("../vfc/ip_cores/ddr3_ctrl_vfc_bank1_32b_32b/user_design/rtl")
        ctrls.remove("bank1_32b_32b")

    if "bank1_64b_32b" in ctrls:
        modules["local"].append("../vfc/ip_cores/ddr3_ctrl_vfc_bank1_64b_32b/user_design/rtl")
        ctrls.remove("bank1_64b_32b")

    # at the end, check and complain if local list of modules is still empty, or if there are any
    # unrecognized controllers left in the top Manifest list of controllers

    if not modules["local"] or ctrls:
        raise SystemExit("[ERROR]:DDR3: The controller type is not recognised! "
                         "It must be one of: bank1_32b_32b, bank1_64b_32b, bank3_32b_32b, bank3_64b_32b, bank4_32b_32b, bank4_64b_32b, bank5_32b_32b, bank5_64b_32b.")

except NameError:
    raise SystemExit("[ERROR]:DDR3: The variable ctrls MUST be defined in the top Manifest!")
