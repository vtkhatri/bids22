# implementation of bids22 - group 4
## deeksha kamath, viraj khatri
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
### input generation
* class `bidsrandomizer`
  * randomizes inputs to fsm and bidders
    * `fsminputsrandomizer_t` struct used to declare `fsminputs_t` struct as `rand`
    * `bidsinputsrandomizer_t` struct used to declare `NUMBIDDERS`x`biddersinputs_t` structs as `rand`
  * no constraints for now
### coverage
* covergroup `bids22covergroup`
  * coverpoints
    * `DUV.state` - `illegal_bin` used to exclude `RESET` state from % coverage
* simulation will try to continue till it gets to 100% coverage
  * not happened after 30mins of simulation
  * to stop, use `Ctrl-c`, this will stop `vcover` from creating coverage report from ucdb
  * use `make vcover` to get coverage report manually if simulation stopped
