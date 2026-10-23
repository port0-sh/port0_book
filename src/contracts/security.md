# Security model

The system is unaudited. No audit report exists. The statements below describe
how the contracts behave, not a guarantee of safety.

## Custody

A pool account holds the assets. No operator holds them. Every operation is a
note that the node consumes against the pool. Reserves are the pool's stored
accounting; the vault is the custody backing it, and `get_reserves` asserts the
vault covers the reserves plus the protocol pot on every read.

## No upgrade path, and one narrow admin power

A pool's fee parameters, P2ID root, registry pointer, and token keys are initial
storage. No procedure sets them after creation. A pool cannot be paused,
upgraded, or reconfigured.

The registry's accepted code commitments, protocol share, expected pool storage
roots, and admin account are initial storage as well. There is no setter for any
of them, so changing an accepted commitment or the protocol share means building
and deploying a new registry account. The `register` procedure only adds pool ids
and asset pairs to its two maps.

The registry has one admin, fixed at creation, with exactly one power: it can
change the register fee, which is the price of listing a pool. The contract places
no bound on that fee, deliberately: raising it to an extreme value is the only
switch the protocol has to stop new registrations, an emergency stop that cannot
touch funds, listed pools, or trading. The cost of that switch is that a
compromised admin key can also freeze registration; recovering from that means a
new registry, which is the same cost as any other policy change, since nothing
about a registry is mutable. The call is a
`registry-config` note; the registry requires the note's sender to be the admin,
requires the target script root to be the register note's own root, and requires
that entry to already be scheduled. The admin therefore cannot reprice any other
note, cannot move funds, cannot list or delist a pool, and cannot change a pool's
parameters. A lost admin key freezes the register fee at its current value; a
stolen key can only raise or lower that fee. Neither loses funds.

## What the registry pins about a pool

A pool's code commitment pins its code, not its storage, and the pool creator
chooses that storage. Registration therefore checks the pool's storage against
values the registry was created with: the note allowlist root, the
transaction-script allowlist root, the fee schedule root, the fee asset, the
active fee policy root, and the allowed fee policy roots. A pool whose allowlist
admits a foreign note could move its vault out through the wallet's
`move_asset_to_note`, and a pool charging in another fee asset could never have
its notes consumed.

The pool's payout script root is checked too, against the registry's own P2ID
root. Every payout note a pool creates uses that root, so a hostile value would
run an attacker script when a recipient consumes a swap or burn payout.

A registry created without those values rejects every pool, so a deployment that
omits them fails closed.

## Public state

Pools and notes are public network accounts. Pool reserves, LP supply, fees,
pot, and oracle readings are on chain and readable by anyone. Pool notes are
public; the protocol does not provide private trading.

## Permissionless flows

Pool creation is permissionless. The registry accepts a code commitment; it does
not screen a token or endorse a pool.

Both collect paths are permissionless. The pool collect note and the
registry-collect note move fees to the destination fixed in registry storage, so
a caller can trigger a payout but cannot redirect it.

## Network auth

A pool and the registry install the network-account auth component. The
component carries a note-script allowlist, a fee policy, and the nonce handling.
The node's transaction builder reads the allowlist to consume notes on the
account's behalf. There is no signing key.

The registry prices its two admitted note kinds, the register note and the
registry-collect note, at the measured schedule (119 base units at verification
base fee 7). Every admitted script root must be priced, because a root the fee
policy does not price aborts fee estimation and the account's auth procedure
rejects that note as an input. The allowlist is initial storage, and the
procedures that mutate it are gated on an authority the account does not
install.

### The registry pins the pool's auth storage

A pool's code commitment pins code, not storage. A pool carrying the accepted
component set could still be built with an allowlist of its own, admitting a
note that moves the pool's assets out through the wallet's
`move_asset_to_note`, and every other registration check would pass.

The pool therefore exposes `get_auth_identity`, which returns the roots of its
two allowlist maps and its fee-schedule map, and the registry stores the
expected roots as initial storage and compares them on every registration. A
registry created without them rejects every pool, so a deployment that forgets
them fails closed. The roots are printed by
`cargo run -p integration --bin auth_slot_ids --release` (slot ids) and read
from a reference pool build by the SDK (`poolAuthRoots`).

## Foreign procedure roots

A pool addresses the registry's `protocol_fee_to`, and the registry addresses
the pool's `get_registry_identity`, the pool's `get_auth_identity`, and the
standard `get_code_commitment`, all by hard-coded MAST root. A contract edit
that shifts a root breaks the call until the constant is updated. The roots are
printed by the integration binaries (`registry_roots`, `auth_slot_ids`) and must
be re-derived after a contract change.

## Note fees

Notes carry a fee, and the executing account pays it from its own vault. A
pool's fee faucet must equal the chain's fee faucet, or the node never consumes
the pool's notes. The chain fee asset is the network's own fee faucet asset,
USDCX on the testnet. It comes from the network faucet and is not minted by this
project.

## Reporting

Vulnerability reports go to hello@port0.sh. The contact is listed in the
[contact chapter](../reference/contact.md).
