import bids22defs::*;
module top;

parameter  NUMTESTS   = 10;
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
// stimulus
//
initial begin : resetblock
    reset_n = 1;
    reset_n = 0;
    repeat (CLOCK_IDLE) @(posedge clk); // under reset for 2 clocks
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
    repeat(CLOCK_IDLE) @(posedge clk); // waiting for reset (2 clocks)
    repeat (NUMTESTS) begin
        assert(inrandoms.randomize());
        @(posedge clk);
    end
    $finish();
end

endmodule : top
