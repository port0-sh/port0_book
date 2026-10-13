# Pool

The `port0` component is the pool account component. It holds the reserves
accounting, the LP supply, the two fee parameters, the protocol pot, and the
price oracle.

## Storage

The pool component declares ten value slots.

| Slot | Type | Encoding |
| --- | --- | --- |
| `token0_asset_key` | Word | token0 asset key |
| `token1_asset_key` | Word | token1 asset key |
| `lp_supply` | Felt | `[supply, 0, 0, 0]` |
| `fees` | Word | `[lp_fee_bps, protocol_fee_share_bps, 0, 0]` |
| `p2id_root` | Word | P2ID script root used for output notes |
| `protocol_pot` | Word | `[amount0, amount1, 0, 0]` |
| `price0_cumulative_last` | Word | u128, four 32-bit limbs, least significant first |
| `price1_cumulative_last` | Word | u128, four 32-bit limbs, least significant first |
| `block_timestamp_last` | Felt | `[timestamp, 0, 0, 0]` |
| `registry_id` | Word | `[0, 0, suffix, prefix]` of the registry account id |

Every slot except `protocol_pot` and the two accumulators is written at account
creation. `protocol_pot` accrues as swaps happen. The LP token key is not a
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
| `collect` | Moves the protocol pot to the protocol account |
| `get_registry_identity` | Returns the registry pointer, token keys, and fee parameters |

`get_registry_identity` returns twelve felts in the order
`[prefix, suffix, token0[0..4], token1[0..4], protocol_fee_share_bps,
lp_fee_bps]`. The registry calls it by foreign procedure invocation at
registration.

## Reserves

The pool does not store reserves. Reserves equal the vault balances of token0
and token1 minus the protocol pot. The vault is the source of truth, and the
protocol pot is the only balance the pool withholds from the curve.

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

`collect` reads the protocol fee destination from the registry by foreign
procedure invocation, moves the protocol pot contents to that account as a P2ID
note, and resets the pot. An empty pot reverts. The destination is not stored in
the pool, so it is rotated in one place and read only on the collect path.

## Configuration

A pool's configuration is its initial storage: `lp_fee_bps`,
`protocol_fee_share_bps`, `p2id_root`, `registry_id`, and the two token asset
keys. The LP token key is derived from the pool's account id. No pool parameter
is settable after creation. The registry rejects a pool whose token pair, fee
share, LP fee tier, or registry pointer disagrees with the registry.
