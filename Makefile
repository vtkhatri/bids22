.PHONY: all build sim

SRC_FILES := bidsinterface.sv bids.sv bidstb.sv
COVERAGE_FILE   := coverage.ucdb

top_module := top
vsim_args := -do "coverage save -onexit $(COVERAGE_FILE) ; run -all"

SUBMISSION_FILE := ece593bids22group4.zip
REMOVABLE_STUFF := $(SUBMISSION_FILE) work

all: vlib vlog vsim vcover

clean:
	rm -fr $(REMOVABLE_STUFF)

vlib:
	vlib work

vlog:
	vlog -lint $(SRC_FILES)

vsim: vlog
	vsim -c work.$(top_module) $(vsim_args)

vcover:
	vcover report -verbose $(COVERAGE_FILE) > coveragereport.txt

zip:
	zip -r ece593bids22group4.zip * -x .git/*
