# HTTP API

The indexer serves a read-only JSON API. Amounts are decimal strings because
`u64` and `u128` exceed the safe integer range of JSON numbers. `spot_price` and
`fee_apr` are display-only `f64` values.

## Cross-origin

The API answers cross-origin only for the origins in `INDEXER_ALLOWED_ORIGINS`.
Only `GET` and `POST` are allowed, without credentials. The refresh route is
state-changing, so no wildcard is accepted. An empty list means same-origin
only.

## Caching

Every response carries an explicit `Cache-Control`. The indexer's view is at
most one poll old, so a lifetime longer than a poll adds staleness and nothing
else.

| Route | `Cache-Control` |
| --- | --- |
| `GET /pools`, `GET /pools/{id}` | `public, max-age=5, must-revalidate` |
| `GET /pools/{id}/history` at `1m` or `5m` | `public, max-age=5, must-revalidate` |
| `GET /pools/{id}/history` at `1h`, `6h`, or `1d` | `public, max-age=15, must-revalidate` |
| `GET /status` | `no-store` |
| `POST /pools/{id}/refresh` | `no-store` |
| Any non-success, including a 404 | `no-store` |

A 404 is uncacheable on purpose: until the registry surfaces a pool, the
indexer answers 404, and a stored copy would leave the pool page saying not
found after the pool exists. The coarser history resolutions get a longer life
because a bucket closes within its own period. `Vary` comes from the CORS layer
and names the origin. A CDN in front of the API either honours these headers or
bypasses its cache for the API path.

## `GET /status`

Returns the indexer state.

| Field | Type | Meaning |
| --- | --- | --- |
| `registry_id` | string or null | Registry account id, hex |
| `last_registry_block` | number or null | Last block a registry read covered |
| `known_pools` | number | Pool ids discovered from the registry |
| `fetched_pools` | number | Pools whose state has been fetched |

## `GET /pools`

Returns one page of pool summaries, keyset paginated by pool id.

| Query | Default | Meaning |
| --- | --- | --- |
| `token` | none | Faucet id, hex or bech32, to keep only pools holding it |
| `limit` | `50` | Page size, clamped to `1..=500` |
| `cursor` | none | The `next_cursor` of the previous page |

Response:

```json
{
  "pools": [ { "id": "0x...", "...": "..." } ],
  "next_cursor": "0x..."
}
```

`next_cursor` is absent on the last page. The list omits each pool's
`fee_schedule`, which is the largest part of a summary and is only needed by a
pool page.

## `GET /pools/{id}`

Returns one pool summary with its `fee_schedule` and the newest history points.
The response is the summary fields below, plus:

| Field | Type | Meaning |
| --- | --- | --- |
| `fee_schedule` | array | One `{ root, amount }` per priced note script root |
| `history` | array | Newest snapshots, default 1m resolution |

## `GET /pools/{id}/history`

Returns the pool's sampled history.

| Query | Default | Meaning |
| --- | --- | --- |
| `resolution` | `1m` | One of `1m`, `5m`, `1h`, `6h`, `1d` |

The response is an array of snapshot objects. An unknown resolution returns
`400`. Without a database the response is an empty array rather than an error:
the pool itself is still served.

## `GET /pools/{id}/activity`

The pool's price observations and its transactions in one read, newest first.
There is one row per price change and one per recorded transaction. A transaction
carries the reserves of the last observation at or before its block, so its row
can be priced; before the first observation it carries none. A transaction at a
block an observation also produced sorts above that observation.

| Query | Default | Meaning |
| --- | --- | --- |
| `resolution` | `1m` | `1m`, `5m`, `1h`, `6h`, `1d`; sets the observation series |
| `limit` | `24` | Rows to return, clamped to `1..=200` |

The response is `{ "samples": [...], "activity": [...] }`. `samples` holds every
bucket of the resolution, for the chart. Each activity row:

| Field | Type | Meaning |
| --- | --- | --- |
| `timestamp` | number | Chain time: the bucket's for an observation, the block's for a transaction |
| `block` | number | Block of the row |
| `reserve0`, `reserve1` | string or absent | Reserves of the last observation at or before this row |
| `trade` | object or absent | The transaction; absent on an observation |

A `trade` carries `kind` (`swap`, `add`, `remove`, `collect`, `other`), `tx_id`,
and the amounts per token in that token's base units: `volume0`/`volume1` (swap
input, protocol fee included), `in0`/`in1` (reserves added), `out0`/`out1`
(reserves paid out), `protocol_fee0`/`protocol_fee1` (pot a collect freed). The
client names them with the pool's symbols and decimals: a swap reads
`Swap 1.2k MICO → 4.4k USDCX`, an add or a remove its two sides, a collect the pot
it freed, and a row the backfill could only identify reads `Unrecorded`.

The client computes the price from the row's reserves and the pool's token
decimals, so the number is formatted in one place and remains exact.

## `GET /pools/{id}/events`

Returns the pool's recorded transactions, newest first. The block stream carries
each transaction header, so one row is one transaction: its id, the block, and
the block's timestamp. The amounts are the pool state's change since the state
the indexer had recorded, read at the transaction's block; that is the
transaction's effect unless the block carried more than one of the pool's
transactions.

| Query | Default | Meaning |
| --- | --- | --- |
| `limit` | `100` | Rows to return, clamped to `1..=500` |

The response is an array of event objects. An unknown pool returns `404`. Without
a database the response is an empty array rather than an error. Transactions
from before the indexer started are not in the log: the backfill path is not
implemented.

| Field | Type | Meaning |
| --- | --- | --- |
| `tx_id` | string | Transaction id, hex |
| `block` | number | Block that carried the transaction |
| `from_block` | number | Block of the state the delta was measured from |
| `exact` | boolean | True when the amounts are this transaction's own. False for a backfilled row, which has none, and for a block that carried more than one of the pool's transactions, where the delta is the block's total |
| `timestamp` | number | The block's timestamp, seconds |
| `kind` | string | `swap`, `add`, `remove`, `collect`, or `other` |
| `volume0`, `volume1` | string | Swap input per token, protocol fee included |
| `in0`, `in1` | string | Reserve0 and reserve1 the transaction added, protocol fee excluded |
| `out0`, `out1` | string | Reserve0 and reserve1 it paid out |
| `lp_fee0`, `lp_fee1` | string | LP fee kept per token, the protocol share removed |
| `protocol_fee0`, `protocol_fee1` | string | Protocol share accrued per token |

## `POST /pools/{id}/refresh`

Marks one pool due at the next scheduler tick. Returns `202` on acceptance,
`404` for an unknown pool id, and `429` with `Retry-After` when the per-pool
cooldown or the global token bucket denies the request. The fetch happens on the
tick, not inline.

## Pool summary fields

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Pool account id, hex |
| `token0`, `token1` | string | Faucet ids, hex |
| `token0_symbol`, `token1_symbol` | string or null | Faucet symbol |
| `token0_decimals`, `token1_decimals` | number or null | Faucet decimals |
| `fee_asset_id` | string or null | Faucet of the network note fee asset |
| `fee_schedule` | array or absent | `{ root, amount }` per note script root; detail only |
| `reserve0`, `reserve1` | string | The pool's stored reserves; the vault covers these plus the protocol pot |
| `lp_supply` | string | LP supply |
| `k` | string | `reserve0 * reserve1` as u128 |
| `spot_price` | number | token1 per token0, decimals cancelled: `(reserve1 / 10^d1) / (reserve0 / 10^d0)`, display only |
| `pot0`, `pot1` | string | Accrued protocol fees |
| `lp_fee_bps` | number | The pool's LP fee tier |
| `protocol_fee_share_bps` | number | The pool's protocol share |
| `block` | number | Block of the last state change |
| `first_seen_unix` | number | Wall-clock second the indexer first saw the pool |
| `last_change_unix` | number | Wall-clock second of the last state change |
| `volume_24h_0`, `volume_24h_1` | string | Trailing 24 h volume per token |
| `swaps_24h`, `adds_24h`, `removes_24h`, `collects_24h` | number | Recorded transactions of that kind in the trailing 24 h, counted from the event log; the interval counts of the state series when no database is configured |
| `lp_fees_24h_0`, `lp_fees_24h_1` | string | Trailing 24 h LP fees per token |
| `protocol_fees_24h_0`, `protocol_fees_24h_1` | string | Trailing 24 h protocol fees per token |
| `swaps_24h`, `adds_24h`, `removes_24h`, `collects_24h` | number | Trailing 24 h activity counts |
| `fee_apr` | number | Annualised fee yield for liquidity providers, as a fraction |
| `fee_apr_window_secs` | number | Seconds the yield is annualised over |

### Fee APR

Fees accrue in whichever token the swapper paid, so both sides are valued in
token0 at the pool's own price before the ratio is taken. That price values the
reserves at `2 * reserve0` in token0 terms, which is the capital the yield is
taken against. The rate is annualised over `fee_apr_window_secs`, which is the
pool's age while it is below 24 hours. A pool watched for ten minutes reports
ten minutes of yield stretched to a year.

## Snapshot fields

| Field | Type | Meaning |
| --- | --- | --- |
| `block` | number | Block of the last state change in the bucket |
| `timestamp` | number | The pool's `block_timestamp_last` |
| `polled_at` | number | Wall-clock second the bucket opened |
| `reserve0`, `reserve1` | string | State at the end of the bucket |
| `open_reserve0`, `open_reserve1` | string | State at the bucket's first sample |
| `high_reserve0`, `high_reserve1` | string | Reserves at the bucket's highest price |
| `low_reserve0`, `low_reserve1` | string | Reserves at the bucket's lowest price |
| `lp_supply` | string | LP supply at the close |
| `k` | string | Constant product at the close |
| `pot0`, `pot1` | string | Protocol pot at the close |
| `price0_cumulative` | string | Cumulative price0 at the close |
| `price1_cumulative` | string | Cumulative price1 at the close |

A snapshot's `timestamp` is the pool's `block_timestamp_last`, so it is zero for
a pool that has never been operated on and unchanged across samples that saw no
state change. `reserve0` and `reserve1` are the close of the bucket. The open
and extreme reserves are stored as pairs because a price is a ratio of two
reserves and only the pair reconstructs it exactly.
