# App configuration

Environment variables are read at build time (`import.meta.env`).

| Variable | Default | Meaning |
| --- | --- | --- |
| `VITE_MIDEN_RPC_URL` | `https://rpc.testnet.miden.io` | Miden node RPC for on-chain reads |
| `VITE_CHAIN_FEE_FAUCET_ID` | `0x4cbdcaffe75f0a317482224dae6436` | Faucet of the chain's fee asset |
| `VITE_PROTOCOL_FEE_RECIPIENT` | (empty) | Expected protocol fee recipient; gates pool creation |
| `VITE_REGISTRY_ID` | (empty) | On-chain pool registry account; empty skips registration |
| `VITE_REGISTRY_REGISTER_FEE` | `210` | Register note consumption fee, in the registry's fee asset; the protocol maximum, so the sponsorship always covers the actual transaction fee |
| `VITE_INDEXER_URL` | (empty) | Indexer base URL; empty disables browsing and the pool page |
| `VITE_PARA_API_KEY` | (empty) | Para API key; empty keeps the Para option disabled |
| `VITE_PARA_ENVIRONMENT` | `BETA` | Para environment; `PRODUCTION` for production builds |

## Protocol fee recipient

`VITE_PROTOCOL_FEE_RECIPIENT` accepts a hex account id or a bech32 address. It
gates pool creation on the create page. The pool's actual protocol fee
destination is `protocol_fee_to` in the registry; the create page reads the
registry's fee policy and builds the pool with the registry's rate.

## Registry

`VITE_REGISTRY_ID` accepts a hex account id or a bech32 address. When set, the
create flow emits a register note after the pool is deployed. The register note
is a network note consumed by the registry account, so registration is
asynchronous: the wallet confirms emission and the node's transaction builder
consumes the note in a later block. `VITE_REGISTRY_REGISTER_FEE` must match the
registry's note fee schedule.

## Indexer

`VITE_INDEXER_URL` is the application's pool source. The home page lists every
pool the indexer serves, and the pool page loads its state and configuration
from it. The indexer reads the on-chain registry for the pool set and each pool
account for reserves, token metadata, and the network note fee schedule. An
empty value disables browsing and the pool page.

The browser fetches the indexer cross-origin in development, so the indexer's
`INDEXER_ALLOWED_ORIGINS` must list the dev app origin. The shipped indexer
`.env.example` lists the Vite ports.

## RPC

In development the RPC is reached through a same-origin proxy (`/rpc.Api`,
configured in `vite.config.ts`), so the browser never sends cross-origin
gRPC-web requests. Production builds talk to the RPC directly. The app targets
the testnet.

## SDK dependency

The app depends on the published `@port0.sh/sdk`, pinned to the exact version
the deployment is tested against. The [runbook](../operations/runbook.md)
covers the deployment.
