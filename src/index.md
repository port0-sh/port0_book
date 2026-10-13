{{#include hero.html}}

# port0.sh

port0.sh is an open-source exchange built on Miden. A constant-product automated
market maker holds a pair of fungible assets in a pool, prices them by the
product of the two reserves, and lets any account trade, deposit, or withdraw
against the pool. Any token can dock.

The name comes from three places. A program that binds to port 0 asks the
operating system for any free port. A free port is a harbor where any ship can
dock. A free port charges no customs duties: goods land and leave without a tax.
The third meaning is the product. The registry accepts a code commitment and
lists the pool. There is no customs house.

## Components

| Component | Repository | Role |
| --- | --- | --- |
| Contracts | `port0_contracts` | Pool account component, registry account component, and note scripts |
| SDK | `port0_sdk` | TypeScript client for quotes, note building, pool reads, and pool operations |
| Indexer | `port0_indexer` | Reads the registry and pools over node RPC and serves an HTTP API |
| App | `port0_app` | Static web application to browse pools, trade, provide liquidity, and create pools |

## Status

port0.sh runs on Miden testnet 0.17.1. The code is unaudited and no audit report
exists. Pools and notes are public network accounts: pool state and XYK notes are
visible on chain. Nothing here is financial advice.

## Reading order

A reader new to the system starts with [the constant-product
AMM](concepts/amm.md) and [accounts and notes](concepts/accounts-and-notes.md).
A builder reading the interfaces continues with [contracts](contracts/overview.md)
and [the SDK](sdk/install.md). An operator deploying the stack reads
[the runbook](operations/runbook.md). The [repositories
chapter](reference/repositories.md) lists the canonical source and every mirror.
