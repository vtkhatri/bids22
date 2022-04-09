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
### testplans (todo: deeksha)
   - [ ] Testing for when X bids the highest amount, Y bids the highest amount and Z bids the highest amount. 
- [ ] Testing for global errors - 1]. Trying to unlock with a bad key 
                 				    2]. Trying to unlock whilst in unlocked state
						    3]. C_start asserted when unlock state is functioning
						    4]. Invalid operation when opcode is not matching the given list
						    5]. Checking for when two bidders bid the same amount amounting to duplicate bids error

- [ ] Testing for bidders’ errors -  1].
                                                       2]. Testing for insufficient funds when the bid amount outweighs the value/balance for particular bidder
							3]. Testing for mask for particular bidder goes zero at the same time bidder makes a bid

- [ ] 
						   
