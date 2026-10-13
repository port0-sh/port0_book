# Capacity

Measured row costs, 10,000 pools, one year. Retention runs five tiers: 1m for
12 h, 5m for 7 d, 1h for 30 d, 6h for 180 d, and 1d forever. The per-pool row
counts are arithmetic on those windows (720 + 2,016 + 720 + 720 bounded, plus
365 a year for the daily tier). The byte figures are the measured 360.3 and 97.4
bytes per row.

`INDEXER_SNAPSHOT_RETENTION=all` keeps every bucket, whose per-pool yearly count
is 525,600 + 105,120 + 8,760 + 1,460 + 365 = 641,305.

| Policy | Snapshot rows | Snapshot storage |
| --- | --- | --- |
| Keep every bucket | 6.41e9/year | 2.31 TB/year |
| Default (bounded tiers) | 4.18e7 total | 15.05 GB, plus 1.32 GB/year |

Activity rows are one per state change. At 100, 1,000, and 10,000 activities per
pool per day, one year costs 35.6 GB, 356 GB, and 3.56 TB. The default activity
retention is 7 days, which holds that to 6.8 GB at 1,000 per day.

## Limits in order of arrival

| Wall | Detail |
| --- | --- |
| Registry read | The node does not return a storage map above 1,000 entries inline, so the inline read of the `pools` map stops at 1,001 pools. The indexer falls back to `SyncAccountStorageMaps`, which has no entry limit. |
| RPC rate | Polling 10,000 pools per 15 s is 667 `get_account` calls per second, each carrying the pool's storage maps and vault. This is not serviceable by a public node. Event-driven fetching is the alternative. |
| Indexer RAM | The in-memory model keeps one open bucket per tier (5 snapshots) and up to 4,096 activities per pool with no global cap. At 10,000 pools the activity ring dominates at about 3.3 GB. |
| API payload | `GET /pools` returns one page, 50 by default and 500 at most, on the order of 1 KB per entry. A client that walks every cursor re-reads about 10 MB per sweep. |
| Disk | 2.31 TB a year under `INDEXER_SNAPSHOT_RETENTION=all`. `VACUUM` needs a second copy, so retention has to drop tables or partitions rather than rows. `DELETE` never returns space to the filesystem. |
| Browser | 10,000 rows re-rendered every 15 s once the user has loaded every page. The first page is 50 rows; full expansion needs virtualization. |
