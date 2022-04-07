# implementation of bids22

* parameterized - can make more bidders with `NUMBIDDERS` parameter
  * default 3
  * X = `bidder[0]`, Y = `bidder[1]`, Z = `bidder[2]`
* states -
  * `RESET` - oh shit state, shouldn't end up here
  * `UNLOCKED` - reset state, allows setting up the parameters
  * `COOLDOWN` - wait state if wrong key was entered while unlocking, wait for *timer* countdown
  * `LOCKED` - expected state after providing key in unlocked state (default 0), bids22 accepts *C_start* now
  * `ROUNDSTARTED` - bids from bidders now accepted, *bidcost* is also subtracted here per bid
  * `ROUNDOVER` - decision on who won, goes to `READYNEXT`
  * `READYNEXT` - ¯\\\_(ツ)_/¯, goes to `LOCKED`
