/***********************************************
 * bidstb.sv - testbench for bids 22
 * authors : Viraj Khatri, Deeksha Kamath
 *
 * Description: Testbench code for generating 
 *              randomized inputs, defining 
 *              covergroups, and setting initial
 *              values to signals. 
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

`define KEY 17

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

        if ($test$plusargs("doallruns")) coverage = 100 * currentruns / runs;
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

        if ($test$plusargs("peredge"))
            $display("%0t --------------------------------------------\n\tbif - %p\n\tbidders - %p\n\ts/ns - %p/%p\n\t",
                      $time, biftb, DUV.bidder, DUV.state, DUV.nextState, completiontracker.showcoverage());
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

    //
    // constraints
    //
    constraint correctkey {
        // always lock with `KEY
        if      (randfsminputs.fsminputs.C_op == bit'(LOCK))   randfsminputs.fsminputs.C_data == `KEY;
        // while unlocking 33% chance for `KEY, otherwise random
        else if (randfsminputs.fsminputs.C_op == bit'(UNLOCK)) randfsminputs.fsminputs.C_data dist {`KEY:/1, ['0:'1]:/2};
        // random everywhere else
        else                                                   randfsminputs.fsminputs.C_data dist {['0:'1]:/1};
    }

    constraint limittimer {
        // when setting timer, limit to 255 clock cycles
        if (randfsminputs.fsminputs.C_op == bit'(SETTIMER)) randfsminputs.fsminputs.C_data < 32'd256;
        // random everywhere else
        else                                                randfsminputs.fsminputs.C_data dist {['0:'1]:/1};
    }

    constraint longerrounds {
        // if already high, twice as likely to stay high
        if (biftb.cin.C_start) randfsminputs.fsminputs.C_start dist {1 :/ 2, 0 :/ 1} ;
        // if already low, twice as likely to stay low
        else                   randfsminputs.fsminputs.C_start dist {1 :/ 1, 0 :/ 2} ;
    }

    constraint someonealwaysactive {
        // ensuring one bidder is always active when masking someone out
        if (randfsminputs.fsminputs.C_op == bit'(SETMASK)) randfsminputs.fsminputs.C_data % 8 != 0;
    }

    //
    // indirect randomization
    //
    function biddersinputs_t getbids(int i);
        biddersinputs_t outbidders;
        bit halfchance;
        bit [7:0] stuffing;
        outbidders = $random; // to make sure if indirect randomization is not done
                              // atleast a default fully random is assigned

        if ($test$plusargs("tokenstarved")) begin
            outbidders.bid = biftb.cin.C_start;
            stuffing = $random;
            outbidders.bidAmt = biftb.bidders_out[i].balance + stuffing;
        end
        else if ($test$plusargs("impatientbidder")) begin
            outbidders.bid = 1;
        end
        else if ($test$plusargs("rudebidder")) begin
            outbidders.bid = ~biftb.cin.C_start;
        end

        return outbidders;
    endfunction

    function fsminputs_t getinputs();
        fsminputs_t outfsms;
        bit [3:0] randopcode;
        bit [NUMBIDDERS-1:0] biddermask;
        bit [7:0] timerrandmax; // timer shouldn't exceed 2^8
        bit [1:0] correctkey;   // 1/4 chance to take correct key
        bit [1:0] togglecstart; // 1/4 chance to toggle c start

        outfsms = $random; // to make sure if indirect randomization is not done
                           // atleast a default fully random is assigned

        case (outfsms.C_op)
            NO_OP: begin
                // ¯\_(ツ)_/¯
            end
            UNLOCK: begin
                outfsms.C_op = UNLOCK;
                correctkey = $random;
                if (correctkey == '1) outfsms.C_data = `KEY;
            end
            LOCK: begin
                outfsms.C_op = LOCK;
                outfsms.C_data = `KEY;
            end
            LOADX: begin
                // ¯\_(ツ)_/¯
            end
            LOADY: begin
                // ¯\_(ツ)_/¯
            end
            LOADZ: begin
                // ¯\_(ツ)_/¯
            end
            SETMASK: begin
                // make sure that atleast 1 bidder is always actived
                biddermask = $random;

                outfsms.C_data = (biddermask == 0) ? '1 : biddermask;
            end
            SETTIMER: begin
                timerrandmax = $random; // limiting to 2^8
                outfsms.C_data = timerrandmax;
            end
            SETBIDCHARGE: begin
                // ¯\_(ツ)_/¯
            end
            default: begin
                // ¯\_(ツ)_/¯
            end
        endcase

        // 75% chance to stay the same, 25% chance to toggle
        // done for longer rounds and breaks
        togglecstart = $random;
        outfsms.C_start = (togglecstart == 2'b00) ? ~biftb.cin.C_start : biftb.cin.C_start;

        return outfsms;

    endfunction
endclass : bidsrandomizer

//
// covergroups
//
covergroup bids22coverstates@(posedge clk);
    option.at_least = 100;
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
    option.at_least = 100;
    coverxwinner: coverpoint biftb.bidders_out[0].win {
        bins xwon = {1};
    }
    coverywinner: coverpoint biftb.bidders_out[1].win {
        bins ywon = {1};
    }
    coverzwinner: coverpoint biftb.bidders_out[2].win {
        bins zwon = {1};
    }
endgroup : bids22coverbidders

covergroup bids22outerrors@(posedge clk);
    option.at_least = 10;
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

initial begin
    forever begin
        @(negedge clk);
        statecg.sample();
        biddercg.sample();
        errorcg.sample();
    end
end

int temp;

//
// stimulus
//
initial begin
    // resetting fsm inputs
    biftb.cin = 0;
    biftb.bidders_in[0] = 0;
    biftb.bidders_in[1] = 0;
    biftb.bidders_in[2] = 0;

    // activating constraints
    inrandoms.constraint_mode(0);
    if ($test$plusargs("correctkey")) inrandoms.correctkey.constraint_mode(1);
    if ($test$plusargs("limittimer")) inrandoms.limittimer.constraint_mode(1);
    if ($test$plusargs("longerrounds")) inrandoms.longerrounds.constraint_mode(1);
    if ($test$plusargs("someonealwaysactive")) inrandoms.someonealwaysactive.constraint_mode(1);

    // waiting for reset (2 clocks)
    repeat(CLOCK_IDLE) @(negedge clk);

    // making everyone win atleast once
    if ($test$plusargs("bidderswinonce")) biftb.makeAllBiddersWin();

    // setting masks if required
    if ($test$plusargs("maskout")) begin
        $value$plusargs("maskout=%d", temp);
        biftb.maskout(temp);
    end

    // testing 1 million tokens for all
    if ($test$plusargs("milliontokens")) begin
        biftb.milliontokens();
    end

    if ($test$plusargs("milliontokens") || $test$plusargs("maskout")) biftb.lock(`KEY);

    if ($test$plusargs("dontrandtillcomplete")) begin
    end
    else randtillcomplete();

    if (completiontracker.currentruns >= completiontracker.runs) $display("run limit (%0d) reached, quitting.", completiontracker.runs);

    $finish();
end

task randtillcomplete();
    do begin
        assert(inrandoms.randomize());

        if ($test$plusargs("probabilisticallyrandom")) begin
            for (int i=0; i<NUMBIDDERS; i++)
                biftb.bidders_in[i] = inrandoms.getbids(i);
            biftb.cin        = inrandoms.getinputs();
        end
        else begin
            biftb.bidders_in = inrandoms.randbidsinputs.biddersinputs;
            biftb.cin        = inrandoms.randfsminputs.fsminputs;
        end

        @(negedge clk);

        completiontracker.currentruns++;
        if (completiontracker.currentruns % completiontracker.printaftertests == 0)
            $display("%0d - coverage - %s", completiontracker.currentruns, completiontracker.showcoverage());
    end
    while (completiontracker.completion() < 100);
endtask : randtillcomplete

//
// checking coverage and winning at the same time
//
initial begin
    forever begin
        @(negedge clk);
        if ($test$plusargs("perclk")) $display("%0t - bidderwin coverage - x %0d, y %0d, z %0d", $time,
                                               biddercg.coverxwinner.get_coverage(),
                                               biddercg.coverywinner.get_coverage(),
                                               biddercg.coverzwinner.get_coverage());
    end
end

// assertions to track winners
initial begin
    if ($test$plusargs("assertwins")) begin
        assert property(@(negedge clk) ~biftb.bidders_out[0].win)
        else $display("%0t - x has won", $time);
        assert property(@(negedge clk) ~biftb.bidders_out[1].win)
        else $display("%0t - y has won", $time);
        assert property(@(negedge clk) ~biftb.bidders_out[2].win)
        else $display("%0t - z has won", $time);
    end
end

endmodule : top
