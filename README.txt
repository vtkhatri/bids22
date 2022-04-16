# implementation of bids22 - group 4
## deeksha kamath, viraj khatri
---
## assignment 2
### input generation
* class `bidsrandomizer`
  * randomizes inputs to fsm and bidders
    * `fsminputsrandomizer_t` struct used to declare `fsminputs_t` struct as `rand`
    * `bidsinputsrandomizer_t` struct used to declare `NUMBIDDERS`x`biddersinputs_t` structs as `rand`
  * no constraints for now
### random testing setup
* upon reset, do not start randomization instantly
* give every bidder a million tokens (`milliontokens()`)
* lock device with key (`lock(KEY)`)
* randomize till 100% coverage or number of runs exhausted
### coverage
* simulation will try to continue till it gets to 100% coverage or tests reache a value
  * can specify value maximum runs with `make runs=<value>` (default 10000)
  * can reduce / increase prints with `make tests=<value>` (default 1000)
* covergroup `bids22covergroup`
  * coverpoints
    * `coverstates` - `illegal_bin` used to exclude `RESET` state from % coverage
    * `coverstatetransitions` - as name states
      * `lock` - state `UNLOCKED => LOCKED`
      * `unlock` - state `LOCKED => UNLOCKED`
      * `badkey` - state `LOCKED => COOLDOWN => LOCKED`
      * `round` - state `LOCKED => ROUNDSTARTED => ROUNDOVER => READYNEXT => LOCKED`
* covergroup `bids22coverbidders`
  * coverpoints
    * 3x cover bidders winning - covering all bidders winning atleast once
* covergroup `bids22outerrors`
  * coverpoints
    * `coverfsmerrors` - check all fsm errors occuring
    * 3x cover bidders errors - check all errors occuring per bidder
* report - `coverage.report`
  * detailed explanation of all bins and coverages at the start
  * summary of all types of coverages at the end
    * condition coverage
    * covergroups coverage
    * FSM state coverage
    * FSM state transition coverage
    * statement coverage
  * issues found on reading the coverage report, found discrepancies
    * all bidders were winners exactly same number of times
      * further directed testing with just 1 possible winner done
      * the fsm was outputting correctly when verifying with display statements on `posedge clk`
      * the coverage was taking one winner as win for all coverpoints, this gave false 100% win coverage
    * `INSUFFICIENT_FUNDS` did not show up in coverage
      * with above directed testing, one bidder was also given `X` tokens and `X` bidAmt
      * due to `bidCost` this should fail with error `INSUFFICIENT_FUNDS`
      * this can be seen with debug display statement, but coverage report does not list this happening
---
## assignment 1
### makefile
* targets -
  * `all` - does `vlib -> vlog -> vsim -> zip`
  * `vlib` - makes `work` library
  * `vlog` - compiles all files listed in `SRC_FILES`
  * `vsim` - simulates `work.top` (has pre-requisite `vlog`)
  * `zip` - makes zipfile for submission
  * `clean` - deletes all deletable files (`REMOVABLE_STUFF`)
### implementation
* `bidsinterface.sv` - everything required for interface
  * `bids22defs`
    * enum definitions for opcodes, error codes for bidders, and error codes for `bids22` output
    * structure definitions for bidders' inputs and outputs (`inputs_t` and `outputs_t`)
  * `bids22interface` - actual interface that defines all ports as inputs outputs as required
    * only 1 modport as everything is hardcoded
    * could be extended to modports for all bidders, but I don't see how that's helpful
* `bids.sv` - actual bids22 machine's fsm code
  * parameterized - can make more bidders with `NUMBIDDERS` parameter
    * default 3
    * X = `bidder[0]`, Y = `bidder[1]`, Z = `bidder[2]`
  * states -
    * `RESET` - falisafe state, shouldn't never end up here
    * `UNLOCKED` - state on coming out of reset, allows setting up the parameters
    * `COOLDOWN` - wait state if wrong key was entered while unlocking, wait for *timer* countdown
    * `LOCKED` - expected state after providing key in unlocked state (default 0), bids22 accepts *C_start* now
    * `ROUNDSTARTED` - bids from bidders now accepted, *bidcost* is also subtracted here per bid
    * `ROUNDOVER` - decision on who won, goes to `READYNEXT`
    * `READYNEXT` - ¯\\\_(ツ)_/¯, goes to `LOCKED`
### testplans
* testing for when X bids the highest amount, Y bids the highest amount and Z bids the highest amount
* testing for global errors -
  * trying to unlock with a bad key
  * trying to unlock whilst in unlocked state
  * `C_start` asserted when already in unlocked state
  * invalid operation when opcode is not matching the given list
  * checking for when two bidders bid the same amount amounting to duplicate bids error
* testing for bidders’ errors -
  * testing for insufficient funds when the bid amount outweighs the value/balance for particular bidder
  * testing for mask for particular bidder goes zero at the same time bidder makes a bid
  * testing for bids being placed when `C_start` is low
