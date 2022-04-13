import bids22defs::*;
module top;

parameter  NUMTESTS   = 10;
parameter  NUMBIDDERS = 3;
parameter  DATAWIDTH  = 32;
localparam BIDAMTBITS = DATAWIDTH/2;

logic clock, reset_n;
bids22interface biftb (clock, reset_n);
bids22          DUV   (biftb.bidmaster);

//
// clock generator
//
parameter  CLOCK_PERIOD = 10;
localparam CLOCK_WIDTH  = CLOCK_PERIOD/2;
parameter  CLOCK_IDLE   = 2;
initial begin
    clock = 1;
    forever #CLOCK_WIDTH clock = ~clock;
end

//
// stimulus
//
initial begin : resetblock
    reset_n = 1;
    reset_n = 0;
    repeat (CLOCK_IDLE) @(posedge clock); // under reset for 2 clocks
    reset_n = 1;
end           : resetblock

//
// random inputs
//
typedef struct {
    rand fsminputs_t fsminputs;
} fsminputsrandomizer_t;

typedef struct {
    rand biddersinputs_t biddersinputs[NUMBIDDERS];
} bidsinputsrandomizer_t;

class bidsrandomizer;
    rand fsminputsrandomizer_t  randfsminputs;
    rand bidsinputsrandomizer_t randbidsinputs;
endclass : bidsrandomizer

bidsrandomizer inrandoms = new;

initial begin
    repeat(CLOCK_IDLE) @(posedge clock); // waiting for reset (2 clocks)
    repeat (NUMTESTS) 
        assert(inrandoms.randomize());
    $finish();
end

endmodule : top
