# Fees

Two basis-point parameters describe the fee on a swap. They are separate, and
the protocol share does not add to the swapper's cost.

| Parameter | Where it lives | Meaning |
| --- | --- | --- |
| `lp_fee_bps` | Pool initial storage, one value from the registry's allowlist | The fee a swapper pays |
| `protocol_fee_share_bps` | Registry value slot, copied into pool initial storage | The protocol's share of the LP fee, in basis points of it |

## Registry share

The registry holds one protocol share. The shipped value is `1200`, which is 12
percent of the LP fee. Every registered pool must carry that share; the
`register` procedure rejects a pool whose share disagrees with the registry.

The registry also holds an allowlist of LP fee tiers. The shipped tiers are 5,
30, and 100 basis points, which are 0.05, 0.30, and 1.00 percent.

## The swap computation

```
lp_fee             = amount_in * lp_fee_bps / 10000
protocol_fee       = lp_fee * protocol_fee_share_bps / 10000
amount_in_with_fee = amount_in * (10000 - lp_fee_bps)
amount_out         = amount_in_with_fee * reserve_out /
                     (reserve_in * 10000 + amount_in_with_fee)
```

The full input enters the vault. The output is computed from the full input
with the LP fee weight, so `amount_out` does not depend on the protocol share.
The pool's reserve grows by `amount_in - protocol_fee`; the pool keeps the LP
fee minus the share, and the share accrues to the protocol pot.

At the shipped share of `1200`, the protocol fee at each tier is:

| `lp_fee_bps` | LP fee | Protocol share of the fee | Protocol fee on a 10,000 input |
| --- | --- | --- | --- |
| 5 | 0.05% | 12% | 0.6 bps, or 0 base units after integer division |
| 30 | 0.30% | 12% | 3.6 bps, or 3 base units after integer division |
| 100 | 1.00% | 12% | 12 bps, or 12 base units |

The protocol fee is `lp_fee_bps * protocol_fee_share_bps / 10000`, computed
with integer division. The table shows the mathematical value and the value the
contract records after flooring.

## Worked example

Reserves: `reserve0 = 1,000,000`, `reserve1 = 2,000,000`. A swap sends `10,000`
of token0 at the 30 bps tier, with the shipped share of `1200`.

| Step | Value |
| --- | --- |
| `lp_fee` | `10,000 * 30 / 10000 = 30` |
| `protocol_fee` | `30 * 1200 / 10000 = 3` (floored from 3.6) |
| `amount_in_with_fee` | `10,000 * 9970 = 99,700,000` |
| `amount_out` | `99,700,000 * 2,000,000 / (1,000,000 * 10000 + 99,700,000) = 19,743` |
| `reserve0_after` | `1,000,000 + 10,000 - 3 = 1,009,997` |
| `reserve1_after` | `2,000,000 - 19,743 = 1,980,257` |

The swapper pays the 30 bps tier. The protocol receives 3 base units of token0,
and the LP side keeps the remaining 27 base units of the fee.

## Collect

Two permissionless notes move value to the protocol account:

| Note | Source | Destination |
| --- | --- | --- |
| collect-note | Everything the pool vault holds above its stored reserves, for each named asset key | The registry's `protocol_fee_to` |
| registry-collect-note | The registry's whole balance, for each named asset key | The registry's `protocol_fee_to` |

Both destinations are fixed in registry storage. A caller can trigger a payout
but cannot redirect it. For token0 and token1 the pool collect also resets the
protocol pot, which its payout includes. A collect that pays nothing for a key
leaves that key untouched. A sweep where every key pays nothing changes no
account state; the collect note is still consumed, so the transaction pays its
fee and moves nothing. When the swept key is the chain fee asset, the contract
leaves the transaction's own fee in the vault (`tx::compute_fee`), so the
epilogue always has enough.

## Sweeping the fees

The SDK ships a sweep for both pots:

```sh
npm run fees:collect -- registry --submit
npm run fees:collect -- pool <pool-id> --submit
```

Without `--submit` the command is a dry run. It reports what is claimable, the
destination, and the cost to the caller, and submits nothing.

Each sweep emits the collect note and a FEE_SPONSORSHIP note for it. Every
network note kind is priced at the protocol maximum (210 base units at the
current base fee), so the prepayment always covers the actual transaction fee;
the remainder stays in the account and a later collect sweeps it. The caller
funds the sponsorship.

The registry sweep moves the registry's whole balance, in the chain fee asset;
that balance is the sponsorship remainder from registers plus any operator
funding, not a register fee paid to the registry. The pool sweep moves one
pool's protocol pot and any credit above its reserves, in the pool's tokens plus
any third asset. The caller is an account whose key is in the SDK's client
store, and it must hold the chain fee asset. The
[runbook](../operations/runbook.md) covers the environment and the wait window.
