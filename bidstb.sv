import bids22defs::*;
module top;

parameter  NUMTESTS   = 100;
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
    repeat (CLOCK_IDLE) @(posedge clk); // under reset for 2 clocks
    reset_n = 1;
end           : resetblock

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
covergroup fsmcovergroup@(posedge clk);
endgroup : fsmcovergroup

bidsrandomizer inrandoms = new;

//
// random bidder and fsm inputs
//
initial begin
    repeat(CLOCK_IDLE) @(posedge clk); // waiting for reset (2 clocks)
    repeat (NUMTESTS) begin
        assert(inrandoms.randomize());
        biftb.bidders_in = inrandoms.randbidsinputs.biddersinputs;
        biftb.cin        = inrandoms.randfsminputs.fsminputs;
        @(posedge clk);
    end
    $finish();
end

//
// monitors
//
initial begin
    $monitor("%0t - biftb - %p\n\t state,ns = %p,%p", $time, biftb, DUV.state, DUV.nextState);
end

endmodule : top
