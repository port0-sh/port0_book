# Errors

The SDK raises two error types. The pure math layer raises `PoolMathError`,
which mirrors the contract's `PoolMathError`. Everything above the math layer
raises `XykError`, whose `code` is a stable string.

## PoolMathError

| Kind | Condition |
| --- | --- |
| `EmptyPool` | The pool is empty on one or both sides |
| `Overflow` | A value would exceed the numeric bound |
| `ZeroAmountIn` | The input amount is zero |
| `ZeroAmountOut` | The output amount is zero |
| `InsufficientLiquidity` | The pool cannot satisfy the operation |
| `Invariant` | Stored reserves and LP supply disagree |

The message string matches the contract's `PoolMathError`.

## XykError

| Code | Condition |
| --- | --- |
| `NOT_A_POOL` | The account has no token asset keys, or the keys are zero |
| `POOL_NOT_FOUND` | The account or registry is not in the local store |
| `POOL_NOT_CONFIGURED` | A required pool slot is missing |
| `MISSING_SLOT` | A named storage slot is absent |
| `INVARIANT` | The vault does not cover the recorded reserves and protocol pot |
| `INVALID_ARGUMENT` | A parameter is out of range or inconsistent |
| `UNSUPPORTED_OPERATION` | The requested operation has no implementation |

## Failure order

`amountOut` raises in this order: `ZeroAmountIn`, `EmptyPool`, `Overflow` for
any input above `MAX_AMOUNT`, `ZeroAmountOut`, `InsufficientLiquidity` when the
output is at least `reserve_out`, and `Overflow` when the resulting reserve is
at least `MAX_AMOUNT`.

`quoteMint` checks `addAmount(reserve, amount)` against `MAX_AMOUNT` before the
ratio branch, so an over-sized deposit reverts even when part of it would be
refunded.

`quoteBurn` raises `InsufficientLiquidity` when the burn would leave less than
`MINIMUM_LIQUIDITY`, and when either payout rounds to zero.

The [reference error table](../reference/errors.md) maps protocol rejections
seen in operation to their cause and fix.
