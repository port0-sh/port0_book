# Limits and failure conditions

## Numeric bounds

Amounts, reserves, and `lp_supply` are u64 values bounded by
`MAX_AMOUNT = 2^57`.

The binding constraint is the swap numerator,
`amount_in_with_fee * reserve_out`. `amount_in_with_fee` is at most
`amount_in * 10000`, so the worst case is `MAX_AMOUNT^2 * 10000`. The value must
stay below `2^128`, which requires `MAX_AMOUNT < 2^64 / 100`. The value `2^57`
satisfies the bound with margin. Mint and burn products stay below `2^126`.

The oracle accumulators saturate at `u128::MAX` rather than wrap, so a consumer
subtracts two readings without modular arithmetic.

## Failure conditions

Each procedure reverts under the conditions below.

### Mint

- The deposit is missing one of the two tokens.
- A deposited amount is above `MAX_AMOUNT`.
- The first deposit mints at most `MINIMUM_LIQUIDITY`.
- A later deposit mints zero liquidity.
- The liquidity out is below `min_lp_out`.

### Burn

- The note carries multiple assets or an asset that is not the LP token.
- The LP amount is zero.
- The pool is empty.
- The amount is above `MAX_AMOUNT`.
- The burn leaves less than `MINIMUM_LIQUIDITY`.
- Either payout rounds to zero.
- A payout is below its minimum.

### Swap

- The note carries multiple assets or an asset that is neither token.
- The input is zero.
- The pool is empty.
- The input or a reserve is above `MAX_AMOUNT`.
- The output is zero or at least `reserve_out`.
- The resulting reserve is above `MAX_AMOUNT`.
- The output is below `min_amount_out`.

### Collect

A key that pays nothing is a no-op. A sweep in which every key pays nothing
consumes the note and moves no value. The procedure reverts only on a failed
registry read or a malformed payout. The note carries at most four asset keys;
the note script rejects a longer key list, which is the most expensive sweep the
fee schedule prices.

### Registry collect

- `p2id_root` is unset.
- The asset key is empty.

A key that pays nothing is a no-op. The note carries at most four asset keys;
the note script rejects a longer key list.

## Deadline

Every feature note except collect carries a `deadline`, a block timestamp. The
pool reverts the note when it executes after that time. A deadline is built
from the last seen block timestamp plus a margin, so a note does not sit
unbounded in the pool's input queue.
