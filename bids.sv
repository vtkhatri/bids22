import bids22defs::*;

module bids22(bids22interface bif);

parameter DATAWIDTH = 32;
parameter NUMBIDDERS = 3;

bidders_t bidder[NUMBIDDERS]; // TODO : parameterized implementation for number of bidders

// taking inputs into the bidders_t structure
assign bidder[0].in = bif.X_in;
assign bidder[1].in = bif.Y_in;
assign bidder[2].in = bif.Z_in;
// giving FSM outputs as bidders_t structure's outputs
assign bif.X_out = bidder[0].out;
assign bif.Y_out = bidder[1].out;
assign bif.Z_out = bidder[2].out;

// misc fsm registers
logic [DATAWIDTH-1:0] timer, cooldownTimer, cooldownTimerValue, key, bidcost;
logic [NUMBIDDERS-1:0] mask;

assign timer = cooldownTimer; // better code readability with following "spec"

typedef enum logic [2:0] {
    RESET,
    UNLOCKED,
    COOLDOWN,
    LOCKED,
    ROUNDSTARTED,
    ROUNDOVER,
    READYNEXT
} states_t;

states_t state, nextState;

// fsm
always@(posedge bif.clk or negedge bif.reset_n) begin
    if (~bif.reset_n) begin
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
                case (bif.C_op)                      // reset the cooldownTimer so that next fraudulent attempt
                    LOCK: begin                      // is also put to correct cooldown duration
                        key <= bif.C_data;
                    end
                    LOADX: begin
                        bidder[0].value <= bif.C_data;
                    end
                    LOADY: begin
                        bidder[1].value <= bif.C_data;
                    end
                    LOADZ: begin
                        bidder[2].value <= bif.C_data;
                    end
                    SETMASK: begin
                        mask <= bif.C_data;
                    end
                    SETTIMER: begin
                        cooldownTimerValue <= bif.C_data;
                    end
                    SETBIDCHARGE: begin
                        bidcost <= bif.C_data;
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
                    if (bidder[i].in.bid)
                        if (bidder[i].value > bidder[i].in.bidAmt + bidcost)
                            bidder[i].value <= bidder[i].value - (bidder[i].in.bidAmt + bidcost);
                    else if (bidder[i].in.retract) bidder[i].lastbid <= 0;
                end
            end
            ROUNDOVER: begin
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
        if (bif.C_start) begin
            nextState = UNLOCKED;
        end
        else if (bif.C_op == LOCK) nextState = LOCKED;
        else                       nextState = UNLOCKED;
    end
    COOLDOWN: begin
        if (cooldownTimer !== 0) nextState = COOLDOWN;
        else                     nextState = LOCKED;
    end
    LOCKED: begin
        nextState = (C_start) ? ROUNDSTARTED : LOCKED;
    end
    ROUNDSTARTED:begin
        nextState = (C_start) ? ROUNDSTARTED : ROUNDOVER;
    end
    ROUNDOVER:begin
        // ¯\_(ツ)_/¯
    end
    READYNEXT: begin
        // ¯\_(ツ)_/¯
    end
    endcase

end

// output logic
always_comb begin
    // equivalent to assign statements
    for (int i=0; i<NUMBIDDERS; i++) begin
        bidder[i].out.balance = bidder[i].value;
        bidder[i].out = 0; // reset values for bidders' output, it's a packed struct
    end

    // reset values for fsm
    bif.ready = 0;
    bif.err = NOERROR;
    bif.roundOver = 0;
    bif.maxBid = 0;

    case (state)
    RESET: begin
        $error("%0t - should never enter RESET state, check", $time);
        // ¯\_(ツ)_/¯
    end
    UNLOCKED: begin
        if (bif.C_start) begin
            $error("%0t - C_start asserted when state is UNLOCKED", $time);
            bif.err = CSTARTWHENUNLOCKED;
        end
        else begin
            case (bif.C_op)
                NO_OP: begin
                end
                UNLOCK: begin
                    $error("%0t - already unlocked", $time);
                    bif.err = ALREADYUNLOCKED;
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
                    $error("%0t - invalid opcode (%b) received in %p state", $time, bif.C_op, state);
                    bif.err = INVALID_OP;
                end
            endcase
        end
    end
    COOLDOWN: begin
        bif.err = BADKEY;
    end
    LOCKED: begin
        // ready to start round now, C_start will be accepted now
        bif.ready = 1;
    end
    ROUNDSTARTED:begin
        if (int i=0; i<NUMBIDDERS; i++) begin
            if (bidder[i].in.bid) begin
                if (mask[i] === 0) begin
                    $error("%0t - bidder[%0d] has been masked out", $time, i);
                    bidder[i].out.err = INVALIDREQUEST;
                end
                else begin
                    if (bidder[i].in.bidAmt + bidcost > bidder[i].value) begin
                        $error("%0t - insufficient funds for bidder[%0d] (bidAmt=%0d, value=%0d, bidCharge=%0d",
                                $time, i, bidder[i].in.bidAmt, bidder[i].value, bidcost);
                        bidder[i].out.err = INSUFFICIENTFUNDS;
                    end else begin
                        bidder[i].out.err = NOBIDERROR;
                    end
                end
            end
        end
    end
    ROUNDOVER:begin
        for (int i=0; i<NUMBIDDERS; i++) begin
            if (bif.maxBid < bidder[i].lastbid) begin
                bif.maxBid = bidder[i].lastbid;
                bidder[i].out.win = 1;
                for (int j=0; j<NUMBIDDERS; j++) begin
                    if (i != j) bidder[j].out.win = 0;
                end
            end
        end
    end
    READYNEXT: begin
    end
    endcase
end

endmodule : bids22
