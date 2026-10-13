# Operations

Each operation runs the local quote, applies the slippage bound, builds the
feature note and its FEE_SPONSORSHIP note, and assembles one transaction
request. The shape is `(client, config, state, params, options?)`.

```ts
swap(client, config, state, params: SwapParams, options?): Promise<SwapOutput>
addLiquidity(client, config, state, params: MintParams, options?): Promise<MintOutput>
removeLiquidity(client, config, state, params: BurnParams, options?): Promise<BurnOutput>
collectFees(client, config, state, params: CollectParams, options?): Promise<OperationOutput>
registerPool(client, config: RegistryConfig, params: RegisterPoolParams, options?): Promise<RegisterPoolOutput>
```

## Outputs

`OperationOutput` is `{ note, sponsorNote, request, fee, feeFaucetId }`.

| Output | Extra fields |
| --- | --- |
| `SwapOutput` | `quote`, `tokenOut`, `minAmountOut` |
| `MintOutput` | `quote`, `minLpOut` |
| `BurnOutput` | `quote`, `minAmount0`, `minAmount1` |
| `RegisterPoolOutput` | `note`, `sponsorNote`, `request`, `fee`, `feeFaucetId` |

## Submission

`SubmitOptions` is `{ submit?: boolean, waitForConfirmation?: boolean }`.
`submit` defaults to `false`: the caller receives the request and hands it to a
wallet adapter. Setting `submit: true` sends the request through the
`MidenClient`.

## Parameters

| Operation | Fields |
| --- | --- |
| `SwapParams` | `sender`, `recipient`, `tokenIn`, `amountIn`, `slippageBps`, `deadline`, optional `serial`, `tag` |
| `MintParams` | `sender`, `recipient`, `amount0`, `amount1`, `slippageBps`, `deadline`, optional `serial`, `tag` |
| `BurnParams` | `sender`, `recipient`, `amountLp`, `slippageBps`, `deadline`, optional `serial`, `tag` |
| `CollectParams` | `sender`, optional `serial` |
| `RegisterPoolParams` | `sender`, `poolId`, `asset0`, `asset1` |

## Helpers

```ts
applySlippage(amount: bigint, slippageBps: bigint): bigint
resolveSwapSide(tokenIn: string, token0: string, token1: string): 0 | 1
deadlineFrom(blockTimestampSeconds: bigint, marginSeconds: bigint): bigint
```

`applySlippage` returns `floor(amount * (10000 - slippageBps) / 10000)` and
throws `INVALID_ARGUMENT` for `slippageBps` outside `[0, 10000)`.

`resolveSwapSide` returns 0 for token0 and 1 for token1, and throws
`INVALID_ARGUMENT` when `tokenIn` matches neither side.

`deadlineFrom` returns `blockTimestampSeconds + marginSeconds`.

## Pool configuration

```ts
type PoolConfig = {
  poolId: AccountId;
  feeFaucetId: AccountId;
  noteFees: PoolNoteFees;
  deadlineMarginSeconds?: bigint;
};

noteFee(noteFees: PoolNoteFees, kind: PoolNoteKind): bigint
DEFAULT_DEADLINE_MARGIN_SECONDS   // 3600n
```

`PoolNoteFees` is `Partial<Record<PoolNoteKind, bigint>>`, and `PoolNoteKind` is
`"mint" | "burn" | "swap" | "collect"`. `noteFee` returns the configured fee for
a kind, or `0n` when unset. The fee schedule is fixed at pool creation and must
be kept by the application for building correct sponsorship notes.

## Pure math

The pure math functions have no WASM dependency and mirror the contract
arithmetic exactly, including check order and rounding.

```ts
isqrt(n: bigint): bigint
divCeil(numerator: bigint, denominator: bigint): bigint

amountOut(amountIn, reserveIn, reserveOut, lpFeeBps, protocolFeeShareBps): SwapQuote
quoteMint(amount0, amount1, reserve0, reserve1, lpSupply): MintQuote
quoteBurn(amountToBurn, reserve0, reserve1, lpSupply): BurnQuote
```

`amountOut` computes:

```
lp_fee             = floor(lp_fee_bps * amount_in / 10000)
protocol_fee       = floor(protocol_fee_share_bps * lp_fee / 10000)
amount_in_with_fee = amount_in * (10000 - lp_fee_bps)
amount_out         = floor(amount_in_with_fee * reserve_out /
                           (reserve_in * 10000 + amount_in_with_fee))
```

The failure order is `ZeroAmountIn`, `EmptyPool`, `Overflow` for any input above
`MAX_AMOUNT`, `ZeroAmountOut`, `InsufficientLiquidity` when `out >= reserve_out`,
and `Overflow` when `reserve_in_after >= MAX_AMOUNT`.

`quoteMint` on the first deposit mints `isqrt(x * y)` LP tokens and retains
`MINIMUM_LIQUIDITY`. On later deposits it mints the smaller of the two
token-contribution ratios, rounds the consumed amounts up with `divCeil`, and
refunds the unused remainder.

`quoteBurn` returns the proportional share of both reserves. A burn that would
leave less than `MINIMUM_LIQUIDITY` throws `InsufficientLiquidity`, as does a
burn whose payout rounds to zero for either token.

## Pool reads

```ts
decodePoolState(account: Account): PoolState
fetchPoolState(getAccount, poolId): Promise<PoolState>
```

`decodePoolState` reads the ten value slots and the vault. Reserves equal the
vault balances of token0 and token1 minus the protocol pot. It throws
`NOT_A_POOL` when the token asset keys are missing or zero, and `INVARIANT` when
a vault balance is below the recorded pot.

`PoolState` fields: `accountId`, `token0Key`, `token1Key`, `token0FaucetId`,
`token1FaucetId`, `lpSupply`, `fees` (`lpFeeBps`, `protocolFeeShareBps`),
`registryId`, `p2idRoot`, `protocolPot` (`amount0`, `amount1`),
`price0CumulativeLast`, `price1CumulativeLast`, `blockTimestampLast`,
`reserve0`, `reserve1`. The protocol fee destination lives on the registry and
is read only when the pool collects.
