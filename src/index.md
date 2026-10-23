{{#include hero.html}}

# port0.sh

port0 is an exchange on Miden, open to anyone. No sign-up, no approval, no
committee. Open a pool for any token, and no one can stop it.

The code is public and can be read, copied, or run independently.

Questions go to [hello@port0.sh](mailto:hello@port0.sh), or to
[Telegram](https://t.me/port0_sh).

## Components

| Component | Repository | Role |
| --- | --- | --- |
| Contracts | `port0_contracts` | Pool account component, registry account component, and note scripts |
| SDK | `port0_sdk` | TypeScript client for quotes, note building, pool reads, and pool operations |
| Indexer | `port0_indexer` | Reads the registry and pools over node RPC and serves an HTTP API |
| App | `port0_app` | Static web application to browse pools, trade, provide liquidity, and create pools |

## Status

port0.sh runs on the Miden testnet and on the Miden partner mainnet as a closed
alpha. The code is unaudited and no audit report exists. Pools and notes are
public network accounts: pool state and pool notes are visible on chain.

## Reading order

A reader new to the system starts with [the constant-product
AMM](concepts/amm.md) and [accounts and notes](concepts/accounts-and-notes.md).
A builder reading the interfaces continues with [contracts](contracts/overview.md)
and [the SDK](sdk/install.md). An operator deploying the stack reads
[the runbook](operations/runbook.md). The [repositories
chapter](reference/repositories.md) lists the canonical source and every mirror.
