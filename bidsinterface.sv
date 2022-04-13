package bids22defs;

parameter DATAWIDTH = 32;
localparam BIDAMTBITS = DATAWIDTH/2;

typedef enum logic [2:0] {
    RESET,
    UNLOCKED,
    COOLDOWN,
    LOCKED,
    ROUNDSTARTED,
    ROUNDOVER,
    READYNEXT
} states_t;

typedef enum logic [2:0] {
    NOERROR,
    BADKEY,
    ALREADYUNLOCKED,
    CSTARTWHENUNLOCKED,
    INVALID_OP,
    DUPLICATEBIDS
} outerrors_t;

typedef enum logic [2:0] {
    NOBIDERROR,
    ROUNDINACTIVE,
    INSUFFICIENTFUNDS,
    INVALIDREQUEST     // bidder is masked out
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
} biddersinputs_t;

typedef struct packed {
    bit ack;
    biderrors_t err;
    bit [DATAWIDTH-1:0] balance;
    bit win;
} biddersoutputs_t;

typedef struct packed {
    biddersinputs_t in;
    biddersoutputs_t out;
    reg [DATAWIDTH-1:0] value;
    reg [DATAWIDTH-1:0] lastbid;
} bidders_t;

typedef struct packed {
    bit [DATAWIDTH-1:0] C_data;
    bit [3:0]           C_op;
    bit                 C_start;
} fsminputs_t;

typedef struct packed {
    bit ready;
    outerrors_t err;
    bit roundOver;
    bit [DATAWIDTH-1:0] maxBid;
} fsmoutputs_t;

endpackage : bids22defs

interface bids22interface (input logic clk, reset_n);

    parameter DATAWIDTH = 32;
    parameter NUMBIDDERS = 3;
    import bids22defs::*;

    // actual bidders
    // bidders_t X, Y, Z;
    // biddersinputs_t X_in, Y_in, Z_in;
    biddersinputs_t  [NUMBIDDERS-1:0] bidders_in;
    // biddersoutputs_t X_out, Y_out, Z_out;
    biddersoutputs_t [NUMBIDDERS-1:0] bidders_out;
    
    // fsm control signals
    fsminputs_t cin;
    // logic [DATAWIDTH-1:0] C_data;
    // logic [3:0] C_op;
    // logic C_start;

    // fsm relevant outputs
    fsmoutputs_t cout;
    // logic ready;
    // outerrors_t err;
    // logic roundOver;
    // logic [DATAWIDTH-1:0] maxBid;

    modport bidmaster(
        input bidders_in,
        output bidders_out,

        input cin,
        output cout
    );
    
endinterface : bids22interface
