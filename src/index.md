{{#include hero.html}}

# port0.sh

port0 is an open source exchange on Miden, a safe harbor for any token. There is
no sign-up, no approval, and no gatekeeper. Trade anything, or open a pool for
any token. No one can stop you or shut it down.

Everything is public: the contracts, the SDK, and the indexer. Run your own
copy.

Write to [hello@port0.sh](mailto:hello@port0.sh).

## Components

| Component | Repository | Role |
| --- | --- | --- |
| Contracts | `port0_contracts` | Pool account component, registry account component, and note scripts |
| SDK | `port0_sdk` | TypeScript client for quotes, note building, pool reads, and pool operations |
| Indexer | `port0_indexer` | Reads the registry and pools over node RPC and serves an HTTP API |
| App | `port0_app` | Static web application to browse pools, trade, provide liquidity, and create pools |

## Status

port0.sh runs on Miden testnet. The code is unaudited and no audit report
exists. Pools and notes are public network accounts: pool state and XYK notes are
visible on chain.

## Reading order

A reader new to the system starts with [the constant-product
AMM](concepts/amm.md) and [accounts and notes](concepts/accounts-and-notes.md).
A builder reading the interfaces continues with [contracts](contracts/overview.md)
and [the SDK](sdk/install.md). An operator deploying the stack reads
[the runbook](operations/runbook.md). The [repositories
chapter](reference/repositories.md) lists the canonical source and every mirror.
