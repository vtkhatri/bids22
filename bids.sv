import bids22defs::*;

module bids22(bids22interface bif);

parameter DATAWIDTH = 32;
parameter NUMBIDDERS = 3;

bidders_t X, Y, Z; // TODO : parameterized implementation for number of bidders

// taking inputs into the bidders_t structure
assign X.in = bif.X_in;
assign Y.in = bif.Y_in;
assign Z.in = bif.Z_in;
// giving FSM outputs as bidders_t structure's outputs
assign bif.X_out = X.out;
assign bif.Y_out = Y.out;
assign bif.Z_out = Z.out;

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
        X.value <= 0;
        Y.value <= 0;
        Z.value <= 0;
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
                        X.value <= bif.C_data;
                    end
                    LOADY: begin
                        Y.value <= bif.C_data;
                    end
                    LOADZ: begin
                        Z.value <= bif.C_data;
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
                if (~bif.C_start) nextState = ROUNDOVER;
                else begin
                end
            end
            ROUNDOVER: begin
            end
            READYNEXT: begin
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
        // if we are here, we have locked with a new key
        // currently do nothing in this state, maybe skippable
        nextState = ROUNDSTARTED;
    end
    ROUNDSTARTED:begin
    end
    ROUNDOVER:begin
    end
    READYNEXT: begin
    end
    endcase

end

// output logic
always_comb begin
    // equivalent to assign statements
    X.out.balance = X.value;
    Y.out.balance = Y.value;
    Z.out.balance = Z.value;

    // reset values for bidders' output, it's a packed struct
    X.out = 0;
    Y.out = 0;
    Z.out = 0;

    // reset values for fsm
    bif.ready = 0;
    bif.err = NOERROR;
    bif.roundOver = 0;
    bif.maxBid = 0;

    case (state)
    RESET: begin
        $error("%0t - should never enter RESET state, check");
        // ¯\_(ツ)_/¯
    end
    UNLOCKED: begin
        if (bif.C_start) begin
            $error("%0t - C_start asserted when state is UNLOCKED");
            bif.err = CSTARTWHENUNLOCKED;
        end
        else begin
            case (bif.C_op)
                NO_OP: begin
                end
                UNLOCK: begin
                    $error("%0t - already unlocked");
                    bif.err = ALREADYUNLOCKED;
                end
                LOCK: begin
                end
                LOADX: begin
                end
                LOADY: begin
                end
                LOADZ: begin
                end
                SETMASK: begin
                end
                SETTIMER: begin
                end
                SETBIDCHARGE: begin
                end
                default: begin
                    $error("%0t - invalid opcode (%b) received in %p state", bif.C_op, state);
                    bif.err = INVALID_OP;
                end
            endcase
        end
    end
    COOLDOWN: begin
        bif.err = BADKEY;
    end
    LOCKED: begin
    end
    ROUNDSTARTED:begin
    end
    ROUNDOVER:begin
    end
    READYNEXT: begin
    end
    endcase
end

endmodule : bids22
