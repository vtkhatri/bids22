.PHONY: all build sim clean gui

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

vsim_gui_args := \
	-do "coverage save -onexit -directive -cvg -codeAll $(COVERAGE_FILE)" \
	+dontrandtillcomplete +bidderswinonce

ifeq ($(random), true)
else
	vsim_args += +probabilisticallyrandom
endif

ifeq ($(debug), peredge)
	vsim_args += +peredge
endif

# cover => s statement, c condition, f fsm

SUBMISSION_FILE := ece593bids22group4.zip
REMOVABLE_STUFF := \
	work/ \
	$(SUBMISSION_FILE) \
	$(COVERAGE_FILE) \
	$(COVERAGE_REPORT)

all: vlib vlog vopt vsim vcover

build: vlog

sim: vopt vsim vcover

gui: vopt guivsim vcover

clean:
	rm -fr $(REMOVABLE_STUFF)

vlib:
	vlib work

vlog:
	vlog $(vlog_args) $(SRC_FILES)

vopt: vlog
	vsim -c work.$(top_module) -do "vopt +cover=csfe $(top_module) -o $(top_module)_opt ; q"

vsim: vopt
	vsim -c -coverage work.$(top_module)_opt $(vsim_args)

guivsim: vopt
	vsim -coverage work.$(top_module)_opt $(vsim_gui_args)


vcover:
	vcover report -verbose -directive -codeAll -code csfe -cvg $(COVERAGE_FILE) -output $(COVERAGE_REPORT)
	vcover stats $(COVERAGE_FILE) >> $(COVERAGE_REPORT)

zip:
	zip -r ece593bids22group4.zip * -x .git/* -x work/*
