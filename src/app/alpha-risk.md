# Closed alpha risk notice

port0.sh runs on the Miden partner mainnet as a closed alpha. Balances are real
funds. The application presents this notice before first use.

## Custody

A pool is a Miden network account. It holds the assets deposited into it and
executes the allowlisted swap, mint, burn, and collect notes. The account has no
signing key, no admin slot, and no upgrade path: its code and its storage are
fixed at deployment. port0.sh controls no pool and cannot move a pool's assets.

The [registry](../contracts/registry.md) is a network account as well. It records
the accepted pool code and the token-pair-to-pool mapping, and it forwards the
protocol fee to a fixed recipient. It has one admin, fixed at creation, whose
only power is to change the fee charged for listing a new pool: it cannot move
funds, list or delist a pool, or change a pool's parameters, and it cannot change
the protocol fee share.

The user's wallet holds the user's keys. A lost key loses the funds, and no party
can recover them.

## Irreversibility

A transaction is final once the network accepts it. There is no rollback, no
chargeback, and no refund. An emitted note stays claimable by its recipient until
consumed.

## Failure modes

| Failure | Effect |
| --- | --- |
| Contract defect | Deposits can be locked or lost |
| Pool economics | A pool's price can move against a deposit; impermanent loss is not a defect |
| Key lost or stolen | The wallet's assets are unrecoverable |
| Network halt | Transactions wait; accepted state is unaffected |
| Fee change | The network's fee parameters can change the cost of a transaction |
| Wallet or application defect | A transaction can be built with the wrong amounts; the chain is the final check |

## Fees

Network fees are paid in the chain's fee asset and are not refundable. The
protocol fee is a share of the LP fee, not an additional charge.
[Fees](../contracts/fees.md) carries the formula and the current values.

## Data

Pool and registry state is public. The application stores its client state and
the acceptance of this notice in the browser. It sends no telemetry.

## Support

Telegram is where the conversation happens: [t.me/port0_sh](https://t.me/port0_sh).
Email [hello@port0.sh](mailto:hello@port0.sh) for inquiries and vulnerability
reports. There is no support desk and no recovery service.

## Acceptance

The application shows this notice on the first visit. On mainnet a modal blocks
the page until the accept button is pressed; the backdrop and the Esc key do not
close it. Acceptance is recorded in the browser under
`port0-app:alpha-risk:v1:mainnet`. On testnet the notice is a dismissible bar
under `port0-app:alpha-risk:v1:testnet`.
