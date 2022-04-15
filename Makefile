.PHONY: all build sim clean

SRC_FILES := bidsinterface.sv bids.sv bidstb.sv
COVERAGE_FILE   := coverage.ucdb
COVERAGE_REPORT := coverage.report

RUNS := 10000
PRINTAFTERTESTS := 1000

top_module := top
vsim_args := \
	-do "coverage save -onexit $(COVERAGE_FILE) ; run -all" \
	+RUNS=$(RUNS) +PRINTAFTERTESTS=$(PRINTAFTERTESTS)

SUBMISSION_FILE := ece593bids22group4.zip
REMOVABLE_STUFF := \
	work/ \
	$(SUBMISSION_FILE) \
	$(COVERAGE_FILE) \
	$(COVERAGE_REPORT)

all: vlib vlog vsim vcover

build: vlog

sim: vsim vcover

clean:
	rm -fr $(REMOVABLE_STUFF)

vlib:
	vlib work

vlog:
	vlog -lint $(SRC_FILES)

vsim: vlog
	vsim -c work.$(top_module) $(vsim_args)

vcover:
	vcover report -verbose $(COVERAGE_FILE) > coverage.report

zip:
	zip -r ece593bids22group4.zip * -x .git/*
