.PHONY: all build sim clean

SRC_FILES := bidsinterface.sv bids.sv bidstb.sv
COVERAGE_FILE   := coverage.ucdb
COVERAGE_REPORT := coverage.report

runs := 10000
tests := 1000

vlog_args := \
	-coveropt 3 \
	+cover=csfe \
	+acc -sv -lint \

top_module := top
vsim_args := \
	-do "coverage save -onexit -directive -cvg -codeAll $(COVERAGE_FILE) ; run -all" \
	+RUNS=$(runs) +PRINTAFTERTESTS=$(tests)

ifeq ($(random), true)
else
	vsim_args += +probabilisticallyrandom
endif

ifeq ($(debug), perclk)
	vsim_args += +peredge
endif

# cover => s statement, c condition, f fsm

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
	vlog $(vlog_args) $(SRC_FILES)

vsim: vlog
	vsim -c work.$(top_module) -do "vopt +cover=csfe $(top_module) -o $(top_module)_opt ; q"
	vsim -c -coverage work.$(top_module)_opt $(vsim_args)

vcover:
	vcover report -verbose -directive -codeAll -code csfe -cvg $(COVERAGE_FILE) -output $(COVERAGE_REPORT)
	vcover stats $(COVERAGE_FILE) >> $(COVERAGE_REPORT)

zip:
	zip -r ece593bids22group4.zip * -x .git/* -x work/*
