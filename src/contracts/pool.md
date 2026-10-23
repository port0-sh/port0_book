# Pool

The `port0` component is the pool account component. It holds the reserves
accounting, the LP supply, the two fee parameters, the protocol pot, and the
price oracle.

## Storage

The pool component declares eleven value slots.

| Slot | Type | Encoding |
| --- | --- | --- |
| `token0_asset_key` | Word | token0 asset key |
| `token1_asset_key` | Word | token1 asset key |
| `lp_supply` | Felt | `[supply, 0, 0, 0]` |
| `reserves` | Word | `[reserve0, reserve1, 0, 0]` |
| `fees` | Word | `[lp_fee_bps, protocol_fee_share_bps, 0, 0]` |
| `p2id_root` | Word | P2ID script root used for output notes |
| `protocol_pot` | Word | `[amount0, amount1, 0, 0]` |
| `price0_cumulative_last` | Word | u128, four 32-bit limbs, least significant first |
| `price1_cumulative_last` | Word | u128, four 32-bit limbs, least significant first |
| `block_timestamp_last` | Felt | `[timestamp, 0, 0, 0]` |
| `registry_id` | Word | `[0, 0, suffix, prefix]` of the registry account id |

Every slot except `reserves`, `protocol_pot`, and the two accumulators is written
at account creation. `reserves` starts at zero and is written by `mint`, `burn`,
and `swap`; `protocol_pot` accrues as swaps happen. The LP token key is not a
slot; the contract derives it from the pool's account id.

## Procedures

| Procedure | Purpose |
| --- | --- |
| `token0_asset_key` | Reads the token0 asset key |
| `token1_asset_key` | Reads the token1 asset key |
| `lp_supply` | Reads the LP supply |
| `get_reserves` | Reads both reserves |
| `get_fees` | Reads both fee parameters |
| `mint` | Adds liquidity and mints LP tokens |
| `burn` | Removes liquidity and burns LP tokens |
| `swap` | Trades one asset for the other |
| `quote_swap` | Computes a swap without modifying state |
| `collect` | Pays the vault balance above the reserves for one asset key to the protocol account |
| `get_registry_identity` | Returns the registry pointer, token keys, and fee parameters |

`get_registry_identity` returns twelve felts in the order
`[prefix, suffix, token0[0..4], token1[0..4], protocol_fee_share_bps,
lp_fee_bps]`. The registry calls it by foreign procedure invocation at
registration.

## Reserves

Reserves are stored accounting: the `reserves` word is authoritative, and the
vault is the custody backing it. `get_reserves` returns the stored word and
asserts the vault covers `reserves + protocol_pot` for both tokens on every
read. A credit the contract did not create (a funding surplus, a stray P2ID, a
sponsorship remainder) is never a reserve and never enters a quote.

## Mint

On the first deposit the pool computes `root = isqrt(reserve0_after *
reserve1_after)` and requires `root > MINIMUM_LIQUIDITY`. It mints `root` LP
tokens and retains `MINIMUM_LIQUIDITY = 1000`; the provider receives
`root - 1000`.

On later deposits the pool mints the smaller of `amount0 * lp_supply / reserve0`
and `amount1 * lp_supply / reserve1`. The amount of each token used rounds up in
the pool's favor with `div_ceil`; the remainder returns to the provider.

## Burn

For a burn of `amount` LP tokens, the pool returns `amount * reserve0 /
lp_supply` of token0 and `amount * reserve1 / lp_supply` of token1, then reduces
`lp_supply`. The burn reverts when `amount > lp_supply - MINIMUM_LIQUIDITY` and
when either payout rounds to zero.

## Swap

The pool computes the LP fee on the full input, carves the protocol share out of
that fee, and computes the output from the full input with the LP fee weight.
The output does not depend on the protocol share.

```
lp_fee             = amount_in * lp_fee_bps / 10000
protocol_fee       = lp_fee * protocol_fee_share_bps / 10000
amount_in_with_fee = amount_in * (10000 - lp_fee_bps)
amount_out         = amount_in_with_fee * reserve_out /
                     (reserve_in * 10000 + amount_in_with_fee)
```

The full input enters the vault. The output leaves the vault. The reserve grows
by `amount_in - protocol_fee`, and the protocol fee is recorded in
`protocol_pot`. The pool keeps the LP fee minus the protocol share.

## Oracle

The oracle updates at the start of each mint, burn, and swap. It computes

```
p0 = (reserve1 << 64) / reserve0
p1 = (reserve0 << 64) / reserve1
```

and adds `p0 * elapsed` and `p1 * elapsed` to the two cumulative values, where
`elapsed` is the block timestamp delta. The accumulators saturate at
`u128::MAX`. A backward timestamp yields an elapsed of zero, and a pool with a
zero reserve returns before updating the accumulators.

## Collect

`collect(asset_key, serial_num)` pays out the vault balance above the recorded
reserves for one named asset key, to the protocol account the registry
designates, as a P2ID note. For token0 and token1 that balance is the protocol
pot plus any credit outside the reserves, and the pot is reset because it was
paid. For any other key it is the whole balance, so a third asset sent to the
pool is recoverable.

When the key is the chain fee asset, the transaction's own fee is left in the
vault with `tx::compute_fee`, so the sweep can drain the fee asset and the
epilogue still pays. A key that pays nothing is a no-op. The destination is not
stored in the pool, so it is rotated in one place and read only on the collect
path.

## Account components

A deployed pool account carries four components:

| Component | Purpose |
| --- | --- |
| `port0` | The AMM: reserves, LP supply, fees, protocol pot, price oracle |
| Basic fungible faucet | The LP token's name, symbol, and decimals, so wallets can render it |
| `CodeInspection` | `get_code_commitment`, which the registry calls over FPI at registration |
| Network auth | The note-script allowlist and fee schedule the node's network transaction builder reads |

The pool is its own LP faucet: the contract derives the LP asset id from the
pool's account id, and the kernel lets an account mint assets whose faucet id is
its own. The standard faucet component is what gives that faucet a name and
symbol; without it a wallet shows the LP token as "Unknown". Its metadata is
fixed when the pool account is built:

| Field | Value |
| --- | --- |
| Symbol | `PO` plus up to five A-Z letters of each token's symbol (`POUSDCXAAA`) |
| Name | `port0 LP <token0>/<token1>` |
| Decimals | `0`; the app shows LP amounts in raw units |
| Max supply | The protocol's maximum fungible amount, `2^63 - 2^31` |

`TokenSymbol` accepts uppercase ASCII letters only, so a digit prefix such as
`P0` is not representable. Because a pool account is a faucet, the app filters
pool ids out of its pool-token pickers.

## Configuration

A pool's configuration is its initial storage: `lp_fee_bps`,
`protocol_fee_share_bps`, `p2id_root`, `registry_id`, and the two token asset
keys. The LP token key is derived from the pool's account id. No pool parameter
is settable after creation. The registry rejects a pool whose token pair, fee
share, LP fee tier, or registry pointer disagrees with the registry.
