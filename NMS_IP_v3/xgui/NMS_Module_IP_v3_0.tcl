# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BBOX_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BBOX_IND_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXIS_S2MM_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXIL_CONF_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXIL_CONF_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IOU_THRESH_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MEM_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "REG_ADDR_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.BBOX_DATA_WIDTH { PARAM_VALUE.BBOX_DATA_WIDTH } {
	# Procedure called to update BBOX_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BBOX_DATA_WIDTH { PARAM_VALUE.BBOX_DATA_WIDTH } {
	# Procedure called to validate BBOX_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.BBOX_IND_WIDTH { PARAM_VALUE.BBOX_IND_WIDTH } {
	# Procedure called to update BBOX_IND_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BBOX_IND_WIDTH { PARAM_VALUE.BBOX_IND_WIDTH } {
	# Procedure called to validate BBOX_IND_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH { PARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH } {
	# Procedure called to update C_M_AXIS_S2MM_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH { PARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH } {
	# Procedure called to validate C_M_AXIS_S2MM_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH { PARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH } {
	# Procedure called to update C_S_AXIL_CONF_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH { PARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXIL_CONF_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH { PARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH } {
	# Procedure called to update C_S_AXIL_CONF_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH { PARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH } {
	# Procedure called to validate C_S_AXIL_CONF_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.IOU_THRESH_WIDTH { PARAM_VALUE.IOU_THRESH_WIDTH } {
	# Procedure called to update IOU_THRESH_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IOU_THRESH_WIDTH { PARAM_VALUE.IOU_THRESH_WIDTH } {
	# Procedure called to validate IOU_THRESH_WIDTH
	return true
}

proc update_PARAM_VALUE.MEM_ADDR_WIDTH { PARAM_VALUE.MEM_ADDR_WIDTH } {
	# Procedure called to update MEM_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MEM_ADDR_WIDTH { PARAM_VALUE.MEM_ADDR_WIDTH } {
	# Procedure called to validate MEM_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.REG_ADDR_WIDTH { PARAM_VALUE.REG_ADDR_WIDTH } {
	# Procedure called to update REG_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.REG_ADDR_WIDTH { PARAM_VALUE.REG_ADDR_WIDTH } {
	# Procedure called to validate REG_ADDR_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.BBOX_DATA_WIDTH { MODELPARAM_VALUE.BBOX_DATA_WIDTH PARAM_VALUE.BBOX_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BBOX_DATA_WIDTH}] ${MODELPARAM_VALUE.BBOX_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.BBOX_IND_WIDTH { MODELPARAM_VALUE.BBOX_IND_WIDTH PARAM_VALUE.BBOX_IND_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BBOX_IND_WIDTH}] ${MODELPARAM_VALUE.BBOX_IND_WIDTH}
}

proc update_MODELPARAM_VALUE.REG_ADDR_WIDTH { MODELPARAM_VALUE.REG_ADDR_WIDTH PARAM_VALUE.REG_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.REG_ADDR_WIDTH}] ${MODELPARAM_VALUE.REG_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.IOU_THRESH_WIDTH { MODELPARAM_VALUE.IOU_THRESH_WIDTH PARAM_VALUE.IOU_THRESH_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IOU_THRESH_WIDTH}] ${MODELPARAM_VALUE.IOU_THRESH_WIDTH}
}

proc update_MODELPARAM_VALUE.MEM_ADDR_WIDTH { MODELPARAM_VALUE.MEM_ADDR_WIDTH PARAM_VALUE.MEM_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MEM_ADDR_WIDTH}] ${MODELPARAM_VALUE.MEM_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH { MODELPARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH PARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH}] ${MODELPARAM_VALUE.C_M_AXIS_S2MM_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH PARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXIL_CONF_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH PARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXIL_CONF_ADDR_WIDTH}
}

