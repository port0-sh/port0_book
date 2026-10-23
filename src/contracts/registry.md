# Registry

The `pool-registry` component is the registry account component. It holds the
canonical pool set, the ordered asset pair index, and the protocol fee policy.
Registration is the only way a pool becomes discoverable by the indexer and the
app.

## Storage

The registry account declares fifteen storage slots.

| Slot | Type | Key | Value |
| --- | --- | --- | --- |
| `accepted_code_commitments` | map | pool code commitment | `1` when accepted |
| `pools` | map | pool id key `[prefix, suffix, 0, 0]` | pool code commitment |
| `assets_to_pool` | map | ordered asset pair `[lo.prefix, lo.suffix, hi.prefix, hi.suffix]` | pool id key |
| `protocol_fee_to` | value | account id word `[0, 0, suffix, prefix]` | protocol fee destination |
| `protocol_fee_share_bps` | value | `[bps, 0, 0, 0]` | protocol share every pool must carry |
| `allowed_lp_fee_bps` | map | LP fee tier in bps | `1` when a pool may charge it |
| `p2id_root` | value | P2ID script root | script root of the payout note, and the root every pool must carry |
| `expected_note_allowlist_root` | value | root | note allowlist root every pool must carry |
| `expected_tx_script_allowlist_root` | value | root | transaction-script allowlist root every pool must carry |
| `expected_fee_schedule_root` | value | root | fee schedule root every pool must carry |
| `expected_fee_asset_id` | value | asset id word | fee asset every pool must charge in |
| `expected_active_fee_policy_root` | value | root | active fee policy root every pool must carry |
| `expected_allowed_fee_policy_roots` | value | root | allowed fee policy roots every pool must carry |
| `admin` | value | account id word `[0, 0, suffix, prefix]` | account allowed to change the register fee |
| `register_note_root` | value | script root | the only script root whose fee the admin may change |

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
9. The pool's note allowlist root, transaction-script allowlist root, and fee
   schedule root equal the values the registry was created with.
10. The pool's fee asset, active fee policy root, and allowed fee policy roots
    equal the values the registry was created with.
11. The pool's payout script root equals the registry's own P2ID root.

It then writes `pools` and `assets_to_pool`. The commitment is read from the
pool's `CodeInspection::get_code_commitment`, the identity fields from the pool's
`get_registry_identity`, and the six pinned storage roots from the pool's
`get_auth_identity` and `get_fee_identity`, all by foreign procedure invocation.
The fee manager's items are a second procedure because a procedure cannot return
six words on the stack.

Check 11 reuses the registry's own `p2id_root`, because both must be the standard
P2ID script: every payout note a pool creates uses it, so a hostile value would
run an attacker script when a recipient consumes a payout.

Check 9 is what keeps a pool from carrying the accepted code with an allowlist
of its own: an admitted note could move the pool's vault out through the
wallet's `move_asset_to_note`. A registry created without those roots rejects
every pool.

## The register fee is adjustable

Registration is permissionless, so what it costs is the only lever against a
flood of pools. The fee is the register note's entry in the registry's own fee
schedule, and the registry exposes `set_register_fee(new_fee, note_root)`:

1. The note sender must equal the `admin` recorded at creation.
2. The new fee must be positive.
3. The script root must already carry a schedule entry with its set marker, so
   only a note the registry already admits can be re-priced.

The script root travels in the call rather than a constant: a note that links
this account's interface is recompiled when the interface changes, which moves
its root, so a constant would be circular. The registry stores the register
note's root as initial storage and refuses any other root, so the setter cannot
touch the collect note's price or the config note's own price. The
`registry-config` note carries the call; it is allowlisted and priced at zero,
so the registry pays its own transaction fee from the register fees it has
accumulated. `npm run registry:set-fee -- <base-units>` emits it.

Registration is not a judgment. The registry accepts a code commitment and
records the pair. It does not endorse a token.

## Code commitment

The accepted commitment covers the pool's full component set: the `port0`
component, `CodeInspection`, the network-account auth, and the fee-policy
components. It changes when any of those change, and the registry must be
seeded with the value the deployed pool produces. The SDK prints the value with
`npm run pool:commitment`.

The current accepted commitment is
`0xb3193d87f91e7a694d84de14c2bea7da627d7068d17a53b38a984a1739e0f0cb`.

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

`collect(asset_key, serial_num)` moves the registry's balance of `asset_key`
above its reserve to `protocol_fee_to` as a P2ID note. It is permissionless: the
destination is fixed in storage, so a caller can only flush accumulated value
toward the protocol. When the key is the chain fee asset, the procedure reserves
`REGISTRY_COLLECT_FEE_HOLD` (119 base units) for the transaction's own epilogue
charge unless the transaction carries a fee-sponsorship note, in which case it
reserves nothing and the whole balance pays out. The value is measured on a
four-key collect, the shape the sweep tooling sends. The procedure reverts when
`p2id_root` is unset or the asset key is empty, and is a no-op when the payout
would be zero.

## Foreign procedure roots

A pool addresses the registry's `protocol_fee_to`, and the registry addresses
the pool's `get_registry_identity`, its `get_auth_identity` and
`get_fee_identity`, and the standard `get_code_commitment`, all
by hard-coded MAST root. Editing either contract shifts those roots, and the
call fails with a message that names a missing procedure root. The roots are
printed by:

```sh
cargo run -p integration --bin registry_roots --release -- <contract-dir>
cargo run -p integration --bin code_inspection_roots
```
