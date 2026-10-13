# Storage and retention

SQLite holds the pool set, token metadata, one row per history bucket, and one
row per classified activity. History reads do not go through the in-memory
model: the API opens its own read-only connection, and WAL lets it read while
the poller writes, so neither waits on the other.

The RAM mirror keeps only the open bucket of each tier, which is all a poll
needs to extend it. Memory is therefore `O(pools)` rather than
`O(pools x rows)`.

## Column types

Every amount is a TEXT column. SQLite's INTEGER is a signed 64-bit value, so a
`u64` above `2^63 - 1` cannot be stored in it and a `u128` never can; both
appear in pool state. `rusqlite` has no `u64` binding. Amounts travel as the
decimal strings the API already uses, and block numbers, timestamps, and
resolution periods take an `i64` that cannot overflow.

## Row cost

The file grows by the measured cost of a row: **360.3 bytes per snapshot** and
**97.4 bytes per activity**, including their indexes. The figures come from
200,000 rows of each type inserted into the shipped schema.

## Retention ladder

Snapshots follow five tiers. Each tier is pruned to its own window on every
write cycle except the last.

| Tier | Resolution | Retained | Rows per pool |
| --- | --- | --- | --- |
| T0 | 1m | 12 h | 720 |
| T1 | 5m | 7 d | 2,016 |
| T2 | 1h | 30 d | 720 |
| T3 | 6h | 180 d | 720 |
| T4 | 1d | forever | 365/year |

A tier is not computed from the one above it. Every poll feeds all five, and
each tier merges the poll into its open bucket: open from the first sample, high
and low from the extremes, close from the newest. The merge is exact for a
candle.

At 10,000 pools the four bounded tiers hold 15.05 GB, and the daily tier adds
1.32 GB a year. `INDEXER_SNAPSHOT_RETENTION=all` keeps every bucket instead.

## Activity retention

Activity rows are one per state change, so they scale with trading rather than
with time alone. At 100, 1,000, and 10,000 activities per pool per day, one year
costs 35.6 GB, 356 GB, and 3.56 TB. The default activity retention is 7 days,
which holds the cost to 6.8 GB at 1,000 activities per pool per day.

## A snapshot

A snapshot is the state at the end of its bucket, plus the bucket's opening and
extreme states. The extremes are stored as reserve pairs, not as a price,
because a price is a ratio of two reserves and only the pair reconstructs it
exactly.
