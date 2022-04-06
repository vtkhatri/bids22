.PHONY: all build sim

SRC_FILES := $(shell find . -type f -name '*.sv')
ifdef oops
	SRC_FILES = bidsinterface.sv bids.sv
endif
top_module := top
vsim_args := -do "run -all"

all: vlib vlog vsim

vlib:
	vlib work

vlog:
	vlog -lint $(SRC_FILES)

vsim: vlog
	vsim -c work.$(top_module) $(vsim_args)

zip:
	zip -r ece593bids22.zip *
