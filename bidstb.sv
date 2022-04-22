/***********************************************
 * bidstb.sv - testbench for bids 22
 * authors : Viraj Khatri, Deeksha Kamath
 *
 * Description:
 *
 ***********************************************/

import bids22defs::*;
module top;

parameter  NUMBIDDERS = 3;
parameter  DATAWIDTH  = 32;
localparam BIDAMTBITS = DATAWIDTH/2;

logic clk, reset_n;
bids22interface biftb (.clk(clk), .reset_n(reset_n));
bids22          DUV   (.bif(biftb.bidmaster), .clk(clk), .reset_n(reset_n));

int xwin = 0;
int ywin = 0;
int zwin = 0;

//
// main place to check progress of simulation
//
class overlord;
    protected int coverage;

    int statecoverage;
    int biddercoverage;
    int outerrorcoverage;
    int currentruns, runs, printaftertests;

    protected int denom; // to average all coverages

    function new();
        currentruns = 0;
        runs = 10000;
        printaftertests = 1000;
        $value$plusargs("RUNS=%d", runs);
        $value$plusargs("PRINTAFTERTESTS=%d", printaftertests);
    endfunction

    // check completion status, returns % in integer
    function int completion();
        denom = 0;
        coverage = 0;

        if ($test$plusargs("coverstates")) begin
            coverage += statecoverage;
            denom++;
        end
        if ($test$plusargs("coverbidders")) begin
            coverage += biddercoverage;
            denom++;
        end
        if ($test$plusargs("coverouterrors")) begin
            coverage += outerrorcoverage;
            denom++;
        end

        if (denom == 0) begin
            coverage = statecoverage + biddercoverage + outerrorcoverage;
            denom = 3;
        end
        coverage = coverage / denom;

        if (currentruns >= runs) coverage = 100;

        return coverage;
    endfunction : completion

    // displaying status of coverages
    function string showcoverage();
        string retdisplay;

        string state, bidder, outerror, coverage;
        state.itoa(statecoverage);
        bidder.itoa(biddercoverage);
        outerror.itoa(outerrorcoverage);

        coverage.itoa(this.completion());

        retdisplay = {"overall-", coverage};

        if ($test$plusargs("coverstates")) retdisplay = {retdisplay, " state-", state};
        if ($test$plusargs("coverbidders")) retdisplay = {retdisplay, " bidders-", bidder};
        if ($test$plusargs("coverouterrors")) retdisplay = {retdisplay, " errors-", outerror};

        if (retdisplay.len() < 12)
            retdisplay = {retdisplay, " state-",  state, " bidders-", bidder, " errors-", outerror};

        return retdisplay;
    endfunction : showcoverage
endclass

// making a overlord to tack completion
overlord completiontracker = new;

//
// clock generator
//
parameter  CLOCK_PERIOD = 10;
localparam CLOCK_WIDTH  = CLOCK_PERIOD/2;
parameter  CLOCK_IDLE   = 2;
initial begin
    clk = 1;
    forever begin
        #CLOCK_WIDTH;
        clk = ~clk;

        completiontracker.statecoverage = statecg.get_coverage();
        completiontracker.biddercoverage = biddercg.get_coverage();
        completiontracker.outerrorcoverage = errorcg.get_coverage();
        completiontracker.currentruns++;

        if ($test$plusargs("peredge"))
            $display("%0t --------------------------------------------\n\tbif - %p\n\tbidders - %p\n\ts/ns - %p/%p\n\t%s\n\t%0d %0d %0d",
                      $time, biftb, DUV.bidder, DUV.state, DUV.nextState, completiontracker.showcoverage(), xwin, ywin, zwin);
    end
end

//
// reset and other stimulus
//
initial begin : resetblock
    reset_n = 1;
    reset_n = 0;
    repeat (CLOCK_IDLE) @(negedge clk); // under reset for 2 clocks
    reset_n = 1;
end : resetblock

//
// randomization of inputs
//
typedef struct {
    rand fsminputs_t fsminputs;
} fsminputsrandomizer_t;

typedef struct {
    rand biddersinputs_t [NUMBIDDERS-1:0] biddersinputs;
} bidsinputsrandomizer_t;

class bidsrandomizer;
    rand fsminputsrandomizer_t  randfsminputs;
    rand bidsinputsrandomizer_t randbidsinputs;
endclass : bidsrandomizer

//
// covergroups
//
covergroup bids22coverstates@(posedge clk);
    option.at_least = 1;
    coverstates: coverpoint DUV.state {
        illegal_bins RESET = {RESET};
    }
    coverstatetransitions: coverpoint DUV.state {
        bins lock = (UNLOCKED => LOCKED);
        bins unlock = (LOCKED => UNLOCKED);
        bins badkey = (LOCKED => COOLDOWN => LOCKED);
        bins round = (LOCKED => ROUNDSTARTED => ROUNDOVER => READYNEXT => LOCKED);
    }
endgroup : bids22coverstates

covergroup bids22coverbidders@(posedge clk);
    option.at_least = 1;
    coverxwinner: coverpoint biftb.bidders_out[0].win;
    coverywinner: coverpoint biftb.bidders_out[1].win;
    coverzwinner: coverpoint biftb.bidders_out[2].win;
endgroup : bids22coverbidders

covergroup bids22outerrors@(posedge clk);
    option.at_least = 1;
    coverfsmerrors: coverpoint biftb.cout.err;
    coverxerrors: coverpoint biftb.bidders_out[0].err;
    coveryerrors: coverpoint biftb.bidders_out[1].err;
    coverzerrors: coverpoint biftb.bidders_out[2].err;
endgroup : bids22outerrors

//
// random bidder and fsm inputs
//
bidsrandomizer inrandoms = new;

bids22coverstates statecg = new;
bids22coverbidders biddercg = new;
bids22outerrors errorcg = new;

`define KEY 17

assert property (@(posedge clk) ~biftb.bidders_out[0].win)
else $display("[ASSERTION] bidder[0] has won");
assert property (@(posedge clk) ~biftb.bidders_out[1].win)
else $display("[ASSERTION] bidder[1] has won");
assert property (@(posedge clk) ~biftb.bidders_out[2].win)
else $display("[ASSERTION] bidder[2] has won");

//
// stimulus
//
initial begin
    // resetting fsm inputs
    biftb.cin = 0;
    biftb.bidders_in[0] = 0;
    biftb.bidders_in[1] = 0;
    biftb.bidders_in[2] = 0;

    // waiting for reset (2 clocks)
    repeat(CLOCK_IDLE) @(negedge clk);

    // making everyone win atleast once
    if ($test$plusargs("bidderswinonce")) biftb.makeAllBiddersWin();

    // testing 1 million tokens for all
    if ($test$plusargs("milliontokens")) begin
        biftb.milliontokens();
        biftb.lock(`KEY);
    end

    if ($test$plusargs("dontrandtillcomplete")) begin
    end
    else randtillcomplete();

    if (completiontracker.currentruns >= completiontracker.runs) $display("run limit (%0d) reached, quitting.", completiontracker.runs);

    $finish();
end

task randtillcomplete();
    do begin
        assert(inrandoms.randomize());

        biftb.bidders_in = inrandoms.randbidsinputs.biddersinputs;
        biftb.cin        = inrandoms.randfsminputs.fsminputs;

        @(negedge clk);

        if (completiontracker.currentruns % completiontracker.printaftertests == 0)
            $display("%0d - coverage - %s", completiontracker.currentruns, completiontracker.showcoverage());
    end
    while (completiontracker.completion() < 100);
endtask : randtillcomplete


endmodule : top
