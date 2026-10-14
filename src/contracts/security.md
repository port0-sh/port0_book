# Security model

The system is unaudited. No audit report exists. The statements below describe
how the contracts behave, not a guarantee of safety.

## Custody

A pool account holds the assets. No operator holds them. Every operation is a
note that the node consumes against the pool. Reserves are the pool's stored
accounting; the vault is the custody backing it, and `get_reserves` asserts the
vault covers the reserves plus the protocol pot on every read.

## No admin and no upgrade path

A pool's fee parameters, P2ID root, registry pointer, and token keys are initial
storage. No procedure sets them after creation. A pool cannot be paused,
upgraded, or reconfigured.

The registry's accepted code commitments and fee policy are initial storage as
well. The registry has no setter for either, so changing an accepted commitment
or the protocol share means building and deploying a new registry account. The
`register` procedure only adds pool ids and asset pairs to its two maps.

## Public state

Pools and notes are public network accounts. Pool reserves, LP supply, fees,
pot, and oracle readings are on chain and readable by anyone. XYK notes are
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

The registry prices both of its admitted note kinds at the protocol maximum,
the register note and the registry-collect note. Every admitted
script root must be priced, because a root the fee policy does not price aborts
fee estimation and the account's auth procedure rejects that note as an input.
The allowlist is initial storage, and the procedures that mutate it are gated on
an authority the account does not install.

## Foreign procedure roots

A pool addresses the registry's `protocol_fee_to`, and the registry addresses
the pool's `get_registry_identity` and the standard `get_code_commitment`, all
by hard-coded MAST root. A contract edit that shifts a root breaks the call
until the constant is updated. The roots are printed by the integration
binaries and must be re-derived after a contract change.

## Note fees

Notes carry a fee, and the executing account pays it from its own vault. A
pool's fee faucet must equal the chain's fee faucet, or the node never consumes
the pool's notes. The chain fee asset on the testnet is USDCX. It comes from the
network faucet and is not minted by this project.

## Reporting

Vulnerability reports go to hello@port0.sh. The contact is listed in the
[contact chapter](../reference/contact.md).
