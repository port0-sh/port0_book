# The constant-product AMM

A port0 pool holds two fungible assets, token0 and token1, and enforces the
invariant `x * y = k` between their reserves. The invariant is maintained on
every operation, so a trade moves the price along the curve rather than
consuming the reserve at a fixed price.

## Reserves and price

The reserve of each token is the pool account's vault balance of that token
minus the accrued protocol pot. The spot price of one token0 in token1 is the
ratio of the two reserves. The pool does not store the reserves: they are read
from the vault at each operation.

## Liquidity

A liquidity provider deposits both tokens and receives LP tokens. The LP token
is a native fungible asset issued by the pool account itself, with no separate
faucet account. An amount `a` of LP tokens represents the fraction `a / lp_supply`
of the reserves.

- On the first deposit the pool mints `sqrt(x * y)` LP tokens and retains
  `MINIMUM_LIQUIDITY = 1000` permanently. The provider receives the remainder.
- On later deposits the pool mints the smaller of the two token-contribution
  ratios. The consumed amounts round up in the pool's favor, and the unused
  remainder returns to the provider.
- A withdrawal burns LP tokens and returns the proportional share of both
  reserves. A burn that would leave less than `MINIMUM_LIQUIDITY` reverts.

## Swaps

A swap sends one token to the pool and receives the other. The output is
computed from the full input with the LP fee weight, so the effective input is
`amount_in * (10000 - lp_fee_bps) / 10000`. The reserve grows by the input minus
the protocol share. The protocol share is carved out of the LP fee, so the
swapper pays the LP fee tier and nothing more.

The `min_amount_out` field on a swap note bounds slippage. The pool reverts the
note when the output would be smaller than the bound.

## The price oracle

The pool maintains two cumulative price accumulators and the timestamp of the
last update. They update at the start of each mint, burn, and swap:

```
p0 = (reserve1 << 64) / reserve0
p1 = (reserve0 << 64) / reserve1
```

Each accumulator adds `p * elapsed`, where `elapsed` is the block timestamp
delta. The accumulators saturate at `u128::MAX` and never wrap, so a consumer
subtracts two readings to obtain the time-weighted price over the interval. A
backward timestamp yields an elapsed of zero, and a pool with a zero reserve
returns before updating the accumulators.

## Quoting without moving assets

`quote_swap` runs the swap computation against the current reserves without
modifying state. It returns the amount out, the resulting reserves, and the
protocol fee, and it is callable by foreign procedure invocation. The SDK ports
the same arithmetic to TypeScript, so an application can quote before it builds
a transaction.
