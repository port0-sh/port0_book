# App configuration

Environment variables are read at build time (`import.meta.env`).

`VITE_NETWORK` selects a per-network defaults table in `src/lib/config.ts`. An
individual variable overrides its entry, so a deployment sets the network and
only the values that differ from it. A mainnet build must set
`VITE_NETWORK=mainnet`.

| Variable | Default | Meaning |
| --- | --- | --- |
| `VITE_NETWORK` | `testnet` | `testnet` or `mainnet`; selects the defaults below |
| `VITE_MIDEN_RPC_URL` | per network | Miden node RPC for on-chain reads |
| `VITE_CHAIN_FEE_FAUCET_ID` | per network | Faucet of the chain's fee asset |
| `VITE_PROVER_URL` | per network | `local`, `testnet`, `devnet`, or a remote prover URL |
| `VITE_NOTE_TRANSPORT_URL` | per network | `testnet`, `devnet`, or a remote transport URL, for private notes |
| `VITE_EXPLORER_URL` | per network | Block explorer base; account ids are appended |
| `VITE_PROTOCOL_FEE_RECIPIENT` | (empty) | Expected protocol fee recipient; gates pool creation |
| `VITE_REGISTRY_ID` | (empty) | On-chain pool registry account; empty skips registration |
| `VITE_REGISTRY_REGISTER_FEE` | `0` | Register note consumption fee, in the registry's fee asset; must match the registry's note fee schedule |
| `VITE_INDEXER_URL` | (empty) | Indexer base URL; empty disables browsing and the pool page |
| `VITE_PARA_API_KEY` | (empty) | Para API key; empty keeps the Para option disabled |
| `VITE_PARA_ENVIRONMENT` | `BETA` | Para environment; `PRODUCTION` for production builds |
| `VITE_BRAND_*` | (see [Branding](overview.md#branding)) | Wordmark, mark text, slogan, and unfurl metadata |

## Networks

| Value | testnet | mainnet |
| --- | --- | --- |
| RPC | `https://rpc.testnet.miden.io` | `https://rpc.cedar.miden.io` |
| Chain fee faucet | `0x4cbdcaffe75f0a317482224dae6436` | `0xe69e6ca6e39df1b10c1e5399399feb` |
| Prover | `testnet` | `https://tx-prover.cedar.miden.io` |
| Note transport | `testnet` | `https://transport.cedar.miden.io` |
| Explorer | `https://testnet.midenscan.com/account` | `https://explorer.cedar.miden.io/account` |

The mainnet endpoints were read from the partner network on 2026-10-22. The
registry id, the pool code commitment, and the protocol fee recipient are
deployed per network and are not network defaults.

## Alpha notice

Each page shows the text of the selected network and, on mainnet, opens a
blocking acknowledgement modal on the first visit. Acceptance is stored under
`port0-app:alpha-risk:v1:<network>`. The terms are in the
[closed alpha risk notice](alpha-risk.md).

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

The node sends the CORS headers a browser needs, so development and builds talk
to the RPC directly. No dev-server proxy is involved.

## SDK dependency

The app depends on the published `@port0.sh/sdk`, pinned to the exact version
the deployment is tested against. The [runbook](../operations/runbook.md)
covers the deployment.
