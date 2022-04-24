/************************************************************
 * bidsinterface.sv - package and interface code for bids22
 * authors : Viraj Khatri, Deeksha Kamath
 *
 * Description: Designed a package and interface that consists 
 *              of typedef structures and enum definitions for 
 *              input, output signals  and fsm signals. Also 
 *              defined tasks that routinely assign million 
 *              tokens to all bidders when invoked and for 
 *              directed testing to make every bidder win with 
 *              respective inputs. 
 *
 *
 ************************************************************/

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


    //
    // tasks to clean up the stimulus initial block
    //
    task makeAllBiddersWin();
        cin.C_op = LOADX;
        cin.C_data = 45;
        @(negedge clk);
        cin.C_op = LOADY;
        cin.C_data = 46;
        @(negedge clk);
        cin.C_op = LOADZ;
        cin.C_data = 47;
        @(negedge clk);
        lock(12);
        @(negedge clk);
        repeat(($random & 3'b011) + 1) begin
            @(negedge clk);
            cin.C_start = 1;
            @(negedge clk);
            bidders_in[0].bid = 1;
            bidders_in[0].bidAmt = 2;
            bidders_in[1].bid = 1;
            bidders_in[1].bidAmt = 1;
            bidders_in[2].bid = 0;
            bidders_in[2].bidAmt = 1;
            @(negedge clk);
            cin.C_start = 0;
            @(negedge clk);
        end
        @(negedge clk);
        if ($test$plusargs("onlyonewinner")) begin
        end
        else begin
            repeat(($random & 3'b011) + 1) begin
                @(negedge clk);
                cin.C_start = 1;
                @(negedge clk);
                bidders_in[0].bid = 1;
                bidders_in[0].bidAmt = 1;
                bidders_in[1].bid = 1;
                bidders_in[1].bidAmt = 2;
                bidders_in[2].bid = 1;
                bidders_in[2].bidAmt = 1;
                @(negedge clk);
                cin.C_start = 0;
                @(negedge clk);
            end
            @(negedge clk);
            repeat(($random & 3'b011) + 1) begin
                @(negedge clk);
                cin.C_start = 1;
                @(negedge clk);
                bidders_in[0].bid = 1;
                bidders_in[0].bidAmt = 1;
                bidders_in[1].bid = 1;
                bidders_in[1].bidAmt = 1;
                bidders_in[2].bid = 1;
                bidders_in[2].bidAmt = 2;
                @(negedge clk);
                cin.C_start = 0;
                @(negedge clk);
            end
            @(negedge clk);
            unlock(12);
            @(negedge clk);
        end

        return;
    endtask : makeAllBiddersWin

    task lock(int key);
        cin = 0;
        @(negedge clk)
        cin.C_op = LOCK;
        cin.C_data = key;
        @(negedge clk);
        @(negedge clk);
        return;
    endtask : lock

    task unlock(int key);
        cin = 0;
        @(negedge clk)
        cin.C_op = UNLOCK;
        cin.C_data = key;
        @(negedge clk);
        @(negedge clk);
        return;
    endtask : unlock

    task milliontokens();
        cin = 0;
        @(negedge clk)
        cin.C_op = LOADX;
        cin.C_data = 1000000;
        @(negedge clk);
        cin.C_op = LOADY;
        cin.C_data = 1000000;
        @(negedge clk);
        cin.C_op = LOADZ;
        cin.C_data = 1000000;
        @(negedge clk);
        cin.C_op = SETTIMER;
        cin.C_op = 1;
        @(negedge clk);
        return;
    endtask : milliontokens

    task maskout(int mask);
        cin = 0;
        @(negedge clk);
        cin.C_op = SETMASK;
        cin.C_data = mask;
        @(negedge clk);
        return;
    endtask : maskout

    
endinterface : bids22interface
