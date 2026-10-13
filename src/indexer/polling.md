# Polling

The scheduler runs on a short tick, but a pool is fetched only when its own
cadence says so. A block subscription moves that schedule forward whenever a
block touches the pool.

| Idle for | Polled every |
| --- | --- |
| < 5 min | 15 s |
| < 1 h | 60 s |
| < 1 d | 10 min |
| >= 1 d | 1 h |

A block names the accounts it changed. The subscription turns activity into an
immediate poll, so a timer is unnecessary for a quiet network. The arrangement
is a fallback in both directions: a dropped stream reconnects from the last
processed block and the cadence keeps polls flowing while it is down, and the
cadence keeps working if the stream never connects. At 10,000 dormant pools the
network cost settles at about 3 requests a second instead of 667.

## Registry discovery

The registry's `pools` map is the pool set. The node returns at most 1,000
entries inline. Above that cap the indexer detects the limit and discovers pools
through the paginated `SyncAccountStorageMaps` endpoint instead, which has no
entry limit. It reads a block range per poll, walks up to 64 pages, and resumes
from the block it reached. Discovery is idempotent, so an overlapping range
costs one read and nothing else.

## Manual refresh

`POST /pools/{id}/refresh` marks one pool due at the next tick. The response is
`202` because the fetch happens on the tick, not inline. The endpoint is limited
to one refresh per pool every 5 seconds and a global token bucket of 20 per
second. A caller that trips either limit gets `429` with `Retry-After`. An
unknown pool id gets `404` before either limit is consulted.

## Vault reads

The vault is requested with the empty word as its `asset_vault_commitment`. The
field is a hint: omitting it means no vault data is returned, and the response
then carries an empty asset list that is indistinguishable from a genuinely
empty vault. A vault the node refuses to enumerate is an error, not a zero
balance.
