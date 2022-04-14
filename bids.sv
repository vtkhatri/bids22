import bids22defs::*;

module bids22(bids22interface bif, input clk, reset_n);

parameter DATAWIDTH = 32;
parameter NUMBIDDERS = 3;

bidders_t bidder[NUMBIDDERS]; // TODO : parameterized implementation for number of bidders

// misc fsm registers
logic [DATAWIDTH-1:0] timer, cooldownTimer, cooldownTimerValue, key, bidcost;
logic [NUMBIDDERS-1:0] mask;

assign timer = cooldownTimer; // better code readability with following "spec"

states_t state, nextState;

// fsm
always@(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        state <= UNLOCKED;
        for (int i=0; i<NUMBIDDERS; i++) begin
            bidder[i].value <= 0;
            bidder[i].lastbid <= 0;
        end
        mask <= 3'b111;
        cooldownTimerValue <= 32'hF;
        cooldownTimer <= 32'hF;
        key <= 0;
        bidcost <= 1;
    end
    else begin
        state <= nextState;
        case (state)
            RESET: begin
                // ¯\_(ツ)_/¯
            end
            UNLOCKED: begin
                cooldownTimer <= cooldownTimerValue; // if previous state was cooldown, then we need to
                case (bif.cin.C_op)                  // reset the cooldownTimer so that next fraudulent attempt
                    LOCK: begin                      // is also put to correct cooldown duration
                        key <= bif.cin.C_data;
                    end
                    LOADX: begin
                        bidder[0].value <= bif.cin.C_data;
                    end
                    LOADY: begin
                        bidder[1].value <= bif.cin.C_data;
                    end
                    LOADZ: begin
                        bidder[2].value <= bif.cin.C_data;
                    end
                    SETMASK: begin
                        mask <= bif.cin.C_data;
                    end
                    SETTIMER: begin
                        cooldownTimerValue <= bif.cin.C_data;
                    end
                    SETBIDCHARGE: begin
                        bidcost <= bif.cin.C_data;
                    end
                endcase
            end
            COOLDOWN: begin
                if (cooldownTimer !== 0) cooldownTimer <= cooldownTimer-1;
            end
            LOCKED: begin
                // ¯\_(ツ)_/¯
            end
            ROUNDSTARTED: begin
                for (int i=0; i<NUMBIDDERS; i++) begin
                    if (bif.bidders_in[i].bid && mask[i] && bif.bidders_out[i].ack)
                        if (bidder[i].value >= bif.bidders_in[i].bidAmt + bidcost) begin
                            bidder[i].value <= bidder[i].value - bidcost;  // only subtracting bidcost on successful bid
                            bidder[i].lastbid <= bif.bidders_in[i].bidAmt; // storing amount of last successful bid
                        end
                    else if (bif.bidders_in[i].retract) bidder[i].lastbid <= 0;
                end
            end
            ROUNDOVER: begin
                for (int i=0; i<NUMBIDDERS; i++) begin
                    // hopefully there's not more than 1 winner
                    if (bif.bidders_out[i].win == 1) bidder[i].value <= bidder[i].value - bidder[i].lastbid;
                    // resetting lastbid register
                    bidder[i].lastbid <= 0;
                end
                // ¯\_(ツ)_/¯
            end
            READYNEXT: begin
                // ¯\_(ツ)_/¯
            end
        endcase
    end
end

// next state logic
always_comb begin
    nextState = RESET;
    case (state)
    RESET: begin
        // ¯\_(ツ)_/¯
    end
    UNLOCKED: begin
        nextState = (bif.cin.C_op == LOCK) ? LOCKED : UNLOCKED;
    end
    COOLDOWN: begin
        nextState = (cooldownTimer != 0) ? COOLDOWN : LOCKED;
    end
    LOCKED: begin
        if (bif.cin.C_start) nextState = ROUNDSTARTED;
        else if (bif.cin.C_op == UNLOCK && bif.cin.C_data != key) nextState = COOLDOWN;
        else nextState = LOCKED;
    end
    ROUNDSTARTED:begin
        nextState = (bif.cin.C_start) ? ROUNDSTARTED : ROUNDOVER;
    end
    ROUNDOVER:begin
        nextState = READYNEXT;
        // ¯\_(ツ)_/¯
    end
    READYNEXT: begin
        nextState = LOCKED;
        // ¯\_(ツ)_/¯
    end
    endcase

end

// output logic
always_comb begin
    // equivalent to assign statements
    for (int i=0; i<NUMBIDDERS; i++) begin
        bif.bidders_out[i].balance = bidder[i].value;
        bif.bidders_out[i] = 0; // reset values for bidders' output, it's a packed struct
        // set invalid request every time C_start is low and bid is high
        if (bif.cin.C_start == 0 && bif.bidders_in[i].bid == 1) bif.bidders_out[i].err = INVALIDREQUEST;
    end

    // reset values for fsm
    bif.cout.ready = 1; // ready in all states except round over when deciding maxbidder
    bif.cout.err = NOERROR;
    bif.cout.roundOver = 0;
    bif.cout.maxBid = 0;

    case (state)
    RESET: begin
        if ($test$plusargs("printerrors")) $error("%0t - should never enter RESET state, check", $time);
        // ¯\_(ツ)_/¯
    end
    UNLOCKED: begin
        if (bif.cin.C_start) begin
            if ($test$plusargs("printerrors")) $error("%0t - C_start asserted when state is UNLOCKED", $time);
            bif.cout.err = CSTARTWHENUNLOCKED;
        end
        else begin
            case (bif.cin.C_op)
                NO_OP: begin
                end
                UNLOCK: begin
                    if ($test$plusargs("printerrors")) $error("%0t - already unlocked", $time);
                    bif.cout.err = ALREADYUNLOCKED;
                end
                LOCK: begin
                    // ¯\_(ツ)_/¯
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
                    // ¯\_(ツ)_/¯
                end
                SETTIMER: begin
                    // ¯\_(ツ)_/¯
                end
                SETBIDCHARGE: begin
                    // ¯\_(ツ)_/¯
                end
                default: begin
                    if ($test$plusargs("printerrors")) $error("%0t - invalid opcode (%b) received in %p state", $time, bif.cin.C_op, state);
                    bif.cout.err = INVALID_OP;
                end
            endcase
        end
    end
    COOLDOWN: begin
        bif.cout.err = BADKEY;
    end
    LOCKED: begin
        // ¯\_(ツ)_/¯
    end
    ROUNDSTARTED:begin
        for (int i=0; i<NUMBIDDERS; i++) begin
            if (bif.bidders_in[i].bid) begin
                if (mask[i] == 0) begin
                    if ($test$plusargs("printerrors")) $error("%0t - bidder[%0d] has been masked out", $time, i);
                    bif.bidders_out[i].err = INVALIDREQUEST;
                    bif.bidders_out[i].ack = 0;
                end
                else begin
                    if (bif.bidders_in[i].bidAmt + bidcost >= bidder[i].value) begin
                        if ($test$plusargs("printerrors"))
                            $error("%0t - insufficient funds for bidder[%0d] (bidAmt=%0d, value=%0d, bidCharge=%0d)",
                                   $time, i, bif.bidders_in[i].bidAmt, bidder[i].value, bidcost);
                        bif.bidders_out[i].err = INSUFFICIENTFUNDS;
                        bif.bidders_out[i].ack = 0;
                    end else begin
                        bif.bidders_out[i].err = NOBIDERROR;
                        bif.bidders_out[i].ack = 1;
                    end
                end
            end
        end

        // also update maxbid every clock cycle
        for (int i=0; i<NUMBIDDERS; i++) begin
            if (bif.cout.maxBid < bidder[i].lastbid) begin
                bif.cout.maxBid = bidder[i].lastbid;
            end
        end

        // duplicate bids check for error output
        for (int i=0; i<NUMBIDDERS; i++) begin
            for (int j=i+1;j<NUMBIDDERS; j++) begin
                if (bif.bidders_in[i].bidAmt == bidder[j].in.bidAmt) begin
                    bif.cout.err = DUPLICATEBIDS;
                    bif.bidders_out[i].ack = 0;
                end
            end
        end
    end
    ROUNDOVER:begin
        bif.cout.roundOver = 1;
        // deciding who wins, so not ready for other inputs
        bif.cout.ready = 0;
        // looping through till maximum is found, maybe use better logic
        // to take advantage of the fact that there can be multiple cycles
        // before the decision is to be taken
        for (int i=0; i<NUMBIDDERS; i++) begin
            if (bif.cout.maxBid < bidder[i].lastbid) begin
                bif.cout.maxBid = bidder[i].lastbid;
                bif.bidders_out[i].win = 1;
                for (int j=0; j<NUMBIDDERS; j++) begin
                    if (i != j) bif.bidders_out[j].win = 0;
                end
            end
        end
    end
    READYNEXT: begin
        // ¯\_(ツ)_/¯
    end
    endcase
end

endmodule : bids22
