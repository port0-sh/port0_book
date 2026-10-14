# Registry

The `pool-registry` component is the registry account component. It holds the
canonical pool set, the ordered asset pair index, and the protocol fee policy.
Registration is the only way a pool becomes discoverable by the indexer and the
app.

## Storage

The registry account declares seven storage slots.

| Slot | Type | Key | Value |
| --- | --- | --- | --- |
| `accepted_code_commitments` | map | pool code commitment | `1` when accepted |
| `pools` | map | pool id key `[prefix, suffix, 0, 0]` | pool code commitment |
| `assets_to_pool` | map | ordered asset pair `[lo.prefix, lo.suffix, hi.prefix, hi.suffix]` | pool id key |
| `protocol_fee_to` | value | account id word `[0, 0, suffix, prefix]` | protocol fee destination |
| `protocol_fee_share_bps` | value | `[bps, 0, 0, 0]` | protocol share every pool must carry |
| `allowed_lp_fee_bps` | map | LP fee tier in bps | `1` when a pool may charge it |
| `p2id_root` | value | P2ID script root | script root of the payout note |

Keys are four-felt words. A pool id key is `[prefix, suffix, 0, 0]`. An ordered
asset pair is `[lo.prefix, lo.suffix, hi.prefix, hi.suffix]`, ordered by
`(prefix, suffix)` as canonical integers.

## Registration

`register(pool_id, asset_0, asset_1)` performs these checks in order:

1. The two assets are not equal.
2. The pool id is not already registered.
3. The asset pair is not already registered.
4. The pool's code commitment is in `accepted_code_commitments`.
5. The pool's registry pointer equals the executing registry.
6. The pool's token keys match the claimed pair in either order.
7. The pool's protocol share equals the registry's `protocol_fee_share_bps`.
8. The pool's LP fee is an entry in `allowed_lp_fee_bps`.

It then writes `pools` and `assets_to_pool`. The commitment is read from the
pool's `CodeInspection::get_code_commitment`, and the remaining fields from the
pool's `get_registry_identity`, both by foreign procedure invocation.

Registration is not a judgment. The registry accepts a code commitment and
records the pair. It does not endorse a token.

## Code commitment

The accepted commitment covers the pool's full component set: the `port0`
component, `CodeInspection`, the network-account auth, and the fee-policy
components. It changes when any of those change, and the registry must be
seeded with the value the deployed pool produces. The SDK prints the value with
`npm run pool:commitment`.

The current accepted commitment is
`0x8349554fb106b3a989119ea10dddab890c7742dc490c747268b9cd112dd06b3a`.

## Pool lookup

`pool_for_assets(asset_0, asset_1)` returns `[found, prefix, suffix, 0]`. The
`found` flag is `1` with the pool id, or all four felts are zero when the pair
has no pool. A zero account id is never returned as a pool.

`is_pair_registered(asset_0, asset_1)` returns the predicate behind that check.
`pool_code_commitment(pool_id)` reads the recorded commitment.

## Fee policy

`protocol_fee_to` returns the protocol fee destination as four felts:
`[prefix, suffix, 0, 0]`. A pool reads it by foreign procedure invocation when
it collects, so the address is set in one place and read only on the collect
path. `protocol_fee_share_bps` returns the share every registered pool must
carry. `allowed_lp_fee_bps` holds the permitted tiers.

## Registry collect

`collect(asset_key, serial_num)` moves the registry's whole balance of
`asset_key` to `protocol_fee_to` as a P2ID note. It is permissionless: the
destination is fixed in storage, so a caller can only flush accumulated value
toward the protocol. When the key is the chain fee asset, the transaction's own
fee is left in the vault (`tx::compute_fee`), so the sweep can drain the fee
asset and the registry still pays the epilogue fee. The procedure reverts when
`p2id_root` is unset or the asset key is empty, and is a no-op when the payout
would be zero.

## Foreign procedure roots

A pool addresses the registry's `protocol_fee_to`, and the registry addresses
the pool's `get_registry_identity` and the standard `get_code_commitment`, all
by hard-coded MAST root. Editing either contract shifts those roots, and the
call fails with a message that names a missing procedure root. The roots are
printed by:

```sh
cargo run -p integration --bin registry_roots --release -- <contract-dir>
cargo run -p integration --bin code_inspection_roots
```
