import bids22defs::*;
module top;

parameter  NUMBIDDERS = 3;
parameter  DATAWIDTH  = 32;
localparam BIDAMTBITS = DATAWIDTH/2;

logic clk, reset_n;
bids22interface biftb (.clk(clk), .reset_n(reset_n));
bids22          DUV   (.bif(biftb.bidmaster), .clk(clk), .reset_n(reset_n));

//
// clock generator
//
parameter  CLOCK_PERIOD = 10;
localparam CLOCK_WIDTH  = CLOCK_PERIOD/2;
parameter  CLOCK_IDLE   = 2;
initial begin
    clk = 1;
    forever #CLOCK_WIDTH clk = ~clk;
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
    option.at_least = 2;
    coverstates: coverpoint DUV.state {
        illegal_bins impossible_state = {RESET};
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
    coveryerrors: coverpoint biftb.bidders_out[0].err;
    coverzerrors: coverpoint biftb.bidders_out[0].err;
endgroup : bids22outerrors

//
// random bidder and fsm inputs
//
bidsrandomizer inrandoms = new;

bids22coverstates statecg = new;
bids22coverbidders biddercg = new;
bids22outerrors errorcg = new;

static int statecoverage;
static int bidercoverage;
static int errorcoverage;

static int currentruns, runs;

initial begin
    // tracking maxruns
    currentruns = 0;
    runs = 10000;
    $value$plusargs("RUNS=%d", runs);

    // resetting fsm inputs
    biftb.cin = 0;
    biftb.bidders_in[0] = 0;
    biftb.bidders_in[1] = 0;
    biftb.bidders_in[2] = 0;

    // waiting for reset (2 clocks)
    repeat(CLOCK_IDLE) @(negedge clk);

    // test state coverage
    $monitor("%0t - statecoverage - %0d, biddercoverage - %0d, errorcoverage - %0d", $time, statecoverage, bidercoverage, errorcoverage);
    if ($test$plusargs("datadump"))
        $monitor("%0t -\n\tstatecoverage - %0d, biddercoverage - %0d, errorcoverage - %0d\
                  \n\tbiftb - %p\n\t bidders - %p\n\tstate,ns - %p,%p\n\tkey - %0d",
                  $time, statecoverage, bidercoverage, errorcoverage, biftb, DUV.bidder, DUV.state, DUV.nextState, DUV.key);

    // making everyone win atleast once
    // makeAllBiddersWin();

    do begin
        assert(inrandoms.randomize());

        biftb.bidders_in = inrandoms.randbidsinputs.biddersinputs;
        biftb.cin        = inrandoms.randfsminputs.fsminputs;

        @(negedge clk);

        statecoverage = statecg.get_coverage();
        bidercoverage = biddercg.get_coverage();
        errorcoverage = errorcg.get_coverage();
        currentruns++;
    end
    while ((statecoverage < 100 || errorcoverage < 100 || bidercoverage < 100) && currentruns < runs);

    if (currentruns == runs) $display("run limit (%0d) reached, quitting.", runs);

    $finish();
end

task makeAllBiddersWin();
    biftb.cin.C_op = LOADX;
    biftb.cin.C_data = 45;
    @(negedge clk);
    biftb.cin.C_op = LOADY;
    biftb.cin.C_data = 46;
    @(negedge clk);
    biftb.cin.C_op = LOADZ;
    biftb.cin.C_data = 47;
    @(negedge clk);
    biftb.cin.C_op = LOCK;
    biftb.cin.C_data = 12;
    @(negedge clk);
    @(negedge clk);
    biftb.cin.C_start = 1;
    @(negedge clk);
    biftb.bidders_in[0].bid = 1;
    biftb.bidders_in[0].bidAmt = 2;
    biftb.bidders_in[1].bid = 1;
    biftb.bidders_in[1].bidAmt = 1;
    biftb.bidders_in[2].bid = 1;
    biftb.bidders_in[2].bidAmt = 1;
    @(negedge clk);
    biftb.cin.C_start = 0;
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    biftb.cin.C_start = 1;
    @(negedge clk);
    biftb.bidders_in[0].bid = 1;
    biftb.bidders_in[0].bidAmt = 1;
    biftb.bidders_in[1].bid = 1;
    biftb.bidders_in[1].bidAmt = 2;
    biftb.bidders_in[2].bid = 1;
    biftb.bidders_in[2].bidAmt = 1;
    @(negedge clk);
    biftb.cin.C_start = 0;
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    biftb.cin.C_start = 1;
    @(negedge clk);
    biftb.bidders_in[0].bid = 1;
    biftb.bidders_in[0].bidAmt = 1;
    biftb.bidders_in[1].bid = 1;
    biftb.bidders_in[1].bidAmt = 1;
    biftb.bidders_in[2].bid = 1;
    biftb.bidders_in[2].bidAmt = 2;
    @(negedge clk);
    biftb.cin.C_start = 0;
    @(negedge clk);
    @(negedge clk);
    biftb.cin.C_op = UNLOCK;
    biftb.cin.C_data = 12;
    @(negedge clk);

    return;
endtask : makeAllBiddersWin
endmodule : top
