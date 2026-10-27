# Cau hinh project. Makefile doc file nay bang include config.mk.
# Chay mingw32-make tai project, hoac dung -C thu_muc_project.
# Duong dan trong config tinh tu project; dung dau /.

TOP_MODULE ?= uart
# Ten module testbench, KHONG phai ten DUT hay ten file.
TB_NAME ?= tb_top
TB_MODULE ?= $(TB_NAME)
INTERFACE_FILE ?= tb_inf.sv
TB_PACKAGE_FILE ?= tb_pkg.sv
TB_TOP_FILE ?= $(TB_NAME).sv

# Ten file trong tc/, bo .sv; KHONG phai ten task hay test UVM.
# De trong TESTNAME neu project khong co file tc rieng.
TESTNAME ?= tc_pkg

# De trong: quet rtl/*.v va rtl/*.sv sau init, sap xep theo ten.
# Neu co package/dependency, liet ke theo thu tu bien dich, vi du:
# RTL_SOURCES = rtl/design_pkg.sv rtl/fifo_sync.sv
# Khong liet ke lai file da duoc include boi source khac.
RTL_SOURCES ?=
TB_SOURCES ?= tb/$(INTERFACE_FILE) tb/$(TB_PACKAGE_FILE) $(if $(strip $(TESTNAME)),tc/$(TESTNAME).sv) tb/$(TB_TOP_FILE)

# Tim QuestaSim qua PATH, khong gan duong dan cai dat cua mot may.
VLIB ?= vlib.exe
VMAP ?= vmap.exe
VLOG ?= vlog.exe
VSIM ?= vsim.exe
VCOVER ?= vcover.exe

# SV class thuong: 0. UVM: 1, can source UVM va thu vien da bien dich.
# Khi USE_UVM=1, dien hai duong dan TUONG DOI tu project, vi du:
# UVM_HOME = third_party/uvm-1.2
# UVM_LIB = third_party/uvm_lib
USE_UVM ?= 0
UVM_HOME ?=
UVM_LIB ?=
UVM_LIB_NAME ?= uvm

RADIX ?= bin
COVER_TYPES ?= bcesft
VLOG_FLAGS ?=
VSIM_FLAGS ?=
