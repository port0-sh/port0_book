# Indexer overview

The indexer reads the chain through the node RPC only. It uses no Miden client,
no store, and no keystore. It polls the on-chain registry for pool ids and each
pool for state, keeps a bounded history in SQLite, and serves the result over
HTTP.

The indexer is the application's pool source. The home page lists every pool it
serves, and the pool page loads state and configuration from it. There is no
local pool list and no manual import.

## What it reads

| Data | Source |
| --- | --- |
| Pool set | Registry `pools` map |
| Reserves, LP supply, pot, fees, oracle | The pool's eleven value slots and its vault |
| Token symbols and decimals | Each faucet's `token_config` slot |
| Note fee schedule and fee asset | The pool's `fee_asset_id` value slot and the `basic_constant_fee` schedule map |
| Activity and 24 h aggregates | Classified reserve and pot deltas between polls |

Reserves are the pool's stored `reserves` word, matching the contract's
`get_reserves`. The indexer checks that the vault covers the reserves plus the
protocol pot; a credit the contract did not create is never a reserve.

## Process shape

The process starts the HTTP API, a registry poll loop, a block subscription, and
a pool scheduler. The registry poll discovers pools. The block subscription
marks a pool due when a block names it as changed. The scheduler fetches pools
whose own cadence says they are due. A SQLite write cycle persists the newest
bucket of each tier and the pending activities.

The API opens its own read-only connection to the same SQLite file. WAL lets the
API read while the poller writes, so neither waits on the other.

## Source

The canonical source is the Radicle repository. GitHub is a mirror. The
[repositories chapter](../reference/repositories.md) lists every location.
