# Indexer configuration

Read from the environment at startup. A `.env` file in the current directory is
loaded first. Real environment variables take precedence, and a missing file is
not an error.

| Variable | Default | Meaning |
| --- | --- | --- |
| `MIDEN_RPC_URL` | `https://rpc.testnet.miden.io` | Node RPC endpoint |
| `PORT0_REGISTRY_ID` | required | Registry account id, hex |
| `INDEXER_LISTEN` | `127.0.0.1:8080` | HTTP listen address. Loopback by default, for an API behind a reverse proxy |
| `INDEXER_ALLOWED_ORIGINS` | (empty) | Comma-separated origins allowed to read the API cross-origin. Empty means same-origin only; no wildcard is accepted |
| `POOL_POLL_SECS` | `15` | Scheduler tick in seconds, clamped to `1..=5`; per-pool cadence is internal |
| `REGISTRY_POLL_SECS` | `60` | Registry poll interval |
| `INDEXER_DB` | `port0_indexer.sqlite` | SQLite path; empty or `off` keeps the index in RAM only |
| `INDEXER_SNAPSHOT_RETENTION` | (empty) | Empty prunes each resolution to its window; `all` keeps every bucket |
| `RUST_LOG` | `port0_indexer=info` | Tracing filter |

## Listen address

The API listens on loopback by default. A deployment that serves the API
directly sets `INDEXER_LISTEN=0.0.0.0:8080`. A deployment behind a reverse proxy
leaves the default and proxies to it.

## Cross-origin reads

Cross-origin reads are closed by default. `INDEXER_ALLOWED_ORIGINS` lists the
origins the API answers, and only `GET` and `POST` are allowed, without
credentials. The refresh route is state-changing, so no wildcard is accepted. An
empty list means same-origin only, which is the default for a service behind a
proxy. A malformed entry is logged and dropped.

The shipped `.env.example` lists the Vite development ports,
`http://localhost:5173` and `http://localhost:5180`, so a local app can fetch
the API cross-origin.

## Database

`INDEXER_DB` holds the pool set, token metadata, one row per history bucket, and
one row per classified activity. An empty value or `off` keeps the index in RAM
only and forgets every series, activity, and yield window on restart.

`INDEXER_SNAPSHOT_RETENTION=all` keeps every bucket. The default prunes each
resolution to its window. See [storage and retention](storage.md).
