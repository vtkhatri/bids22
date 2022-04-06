package bids22defs;

parameter DATAWIDTH = 32;
localparam BIDAMTBITS = DATAWIDTH/2;

typedef enum logic [2:0] {
    NOERROR,
    BADKEY,
    ALREADYUNLOCKED,
    CSTARTWHENUNLOCKED,
    INVALID_OP
} outerrors_t;

typedef enum logic [1:0] {
    NOBIDERROR,
    ROUNDINACTIVE,
    INSUFFICIENTFUNDS,
    INVALIDREQUEST
} biderrors_t;

typedef enum logic [3:0] {
    NO_OP,
    UNLOCK,
    LOCK,
    LOADX,
    LOADY,
    LOADZ,
    SETMASK,
    SETTIMER,
    SETBIDCHARGE
} opcodes_t;

typedef struct packed {
    bit [BIDAMTBITS-1:0] bidAmt;
    bit bid;
    bit retract;
} inputs_t;

typedef struct packed {
    bit ack;
    bit [1:0] err;
    bit [DATAWIDTH-1:0] balance;
    bit win;
} outputs_t;

typedef struct packed {
    inputs_t in;
    outputs_t out;
    reg [DATAWIDTH-1:0] value;
} bidders_t;

endpackage : bids22defs

interface bids22interface (input logic clk, reset_n);

    parameter DATAWIDTH = 32;
    import bids22defs::*;

    // actual bidders
    // bidders_t X, Y, Z;
    inputs_t X_in, Y_in, Z_in;
    outputs_t X_out, Y_out, Z_out;
    
    // fsm control signals
    logic [DATAWIDTH-1:0] C_data;
    logic [3:0] C_op;
    logic C_start;

    // fsm relevant outputs
    logic ready;
    outerrors_t err;
    logic roundOver;
    logic [DATAWIDTH-1:0] maxBid;

    modport singlebidder(
        input X_in, Y_in, Z_in,
        output X_out, Y_out, Z_out
    );
    
endinterface : bids22interface
