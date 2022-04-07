.PHONY: all build sim

SRC_FILES := $(shell find . -type f -name '*.sv')
ifdef oops # making sure that interface files is compiled before normal file
           # because all definitions required by bids22 are in bids22interface
	SRC_FILES = bidsinterface.sv bids.sv
endif

top_module := top
vsim_args := -do "run -all"

SUBMISSION_FILE := ece593bids22group4.zip
REMOVABLE_STUFF := $(SUBMISSION_FILE)

all: vlib vlog vsim zip

clean:
	rm -fr $(REMOVABLE_STUFF)


vlib:
	vlib work

vlog:
	vlog -lint $(SRC_FILES)

vsim: vlog
	vsim -c work.$(top_module) $(vsim_args)

zip:
	zip -r ece593bids22group4.zip *
