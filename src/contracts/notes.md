# Notes

Every pool operation is a note sent to the pool account. Registration and
registry collection are notes sent to the registry account. This chapter lists
each note, the assets it carries, and the felts it reads from note storage.

| Note | Assets | Note storage (felts, in order) |
| --- | --- | --- |
| mint-note | token0, token1 | pool id (2), recipient (2), serial (4), tag (1), deadline (1), `min_lp_out` (1) |
| burn-note | LP token | pool id (2), recipient (2), serial (4), tag (1), deadline (1), `min_amount0` (1), `min_amount1` (1) |
| swap-note | token0 or token1 | pool id (2), recipient (2), serial (4), tag (1), deadline (1), `min_amount_out` (1) |
| collect-note | none | pool id (2), serial (4), one asset key (4) per swept asset |
| register-note | none | registry id (2), pool id (2), asset0 (2), asset1 (2) |
| registry-collect-note | none | registry id (2), serial (4), one asset key (4) per swept asset |

Account ids are two felts, prefix then suffix. A serial is four felts. `deadline`
is a block timestamp; the note reverts if the pool executes it after that time.
The `min_*` fields bound slippage.

## mint-note

Deposits token0 and token1. The pool mints LP tokens to the recipient. On the
first mint the pool mints `sqrt(x * y)` LP tokens and retains
`MINIMUM_LIQUIDITY = 1000` permanently; the provider receives the remainder. If
the deposited ratio differs from the pool ratio, the pool refunds the excess of
one token to the recipient.

## burn-note

Burns LP tokens. The pool returns a proportional share of both reserves to the
recipient. The burn reverts when `amount_to_burn > lp_supply -
MINIMUM_LIQUIDITY` and when either payout rounds to zero.

## swap-note

Sends one token. The pool pays out the other token, less fees. `min_amount_out`
reverts the trade when the output would be smaller.

## collect-note

Moves everything the pool's vault holds above its recorded reserves for each
named asset key to the protocol account the registry designates. For token0 and
token1 that is the protocol pot plus any credit outside the reserves, and the
pot is reset because it was paid; for any other key it is the whole balance, so
a third asset sent to the pool is recoverable. The note is permissionless: the
destination is fixed in the registry, so a caller can only flush value toward
it. When the key is the chain fee asset, the transaction's own fee is left in
the vault for the epilogue.

## register-note

Registers the pool in the registry. The note targets the registry account and
carries the registry id, the pool id, and the two token faucet ids. The
registry's `register` procedure performs the checks listed in the
[registry chapter](registry.md).

## registry-collect-note

Moves the registry's whole balance of each named asset to the protocol account.
The note carries the registry id, a serial, and one four-felt asset key per
swept asset. Like a pool collect, it is permissionless and the destination is
fixed in storage. The registry leaves the transaction's own fee in its vault
when the swept key is the fee asset.

## Fee sponsorship

A feature note does not carry its own consumption fee. A separate
FEE_SPONSORSHIP note carries exactly one fungible asset, the fee amount in the
fee faucet asset, and the feature note id in its storage. The two notes are
consumed together by the node's transaction builder. The registry-collect note
is priced at the protocol maximum and sponsored like a pool collect; the
registry's `collect` also leaves the transaction's own fee in its vault.
