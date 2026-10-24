# App configuration

Environment variables are read at build time (`import.meta.env`).

`VITE_NETWORK` selects a per-network defaults table in `src/lib/config.ts`. An
individual variable overrides its entry, so a deployment sets the network and
only the values that differ from it. `VITE_NETWORK` takes `testnet`, `devnet`,
`localnet`, or `mainnet`, and an unrecognised value fails the build rather than
silently pointing a deployment at the wrong chain.

| Variable | Default | Meaning |
| --- | --- | --- |
| `VITE_NETWORK` | `testnet` | `testnet`, `devnet`, `localnet`, or `mainnet`; selects the defaults below |
| `VITE_MIDEN_RPC_URL` | per network | Miden node RPC for on-chain reads |
| `VITE_CHAIN_FEE_FAUCET_ID` | per network | Faucet of the chain's fee asset |
| `VITE_PROVER_URL` | per network | `local`, `testnet`, `devnet`, or a remote prover URL |
| `VITE_NOTE_TRANSPORT_URL` | per network | `testnet`, `devnet`, or a remote transport URL, for private notes |
| `VITE_EXPLORER_URL` | per network | Block explorer base; account ids are appended |
| `VITE_REGISTRY_ID` | (empty) | On-chain pool registry account; empty skips registration |
| `VITE_INDEXER_URL` | (empty) | Indexer base URL; empty disables browsing and the pool page |
| `VITE_PARA_API_KEY` | (empty) | Para API key; empty keeps the Para option disabled |
| `VITE_PARA_ENVIRONMENT` | `BETA` | Para environment; `PRODUCTION` for production builds |
| `VITE_BRAND_*` | (see [Branding](overview.md#branding)) | Wordmark, mark text, slogan, and unfurl metadata |

## Networks

| Value | testnet | mainnet | devnet | localnet |
| --- | --- | --- | --- | --- |
| RPC | `https://rpc.testnet.miden.io` | `https://rpc.cedar.miden.io` | `https://rpc.devnet.miden.io` | `http://localhost:57291` |
| Chain fee faucet | `0x4cbdcaffe75f0a317482224dae6436` | `0xe69e6ca6e39df1b10c1e5399399feb` | (set explicitly) | (set explicitly) |
| Prover | `testnet` | `https://tx-prover.cedar.miden.io` | `devnet` | `local` |
| Note transport | `testnet` | `https://transport.cedar.miden.io` | `devnet` | `local` |
| Explorer | `https://testnet.midenscan.com/account` | `https://explorer.cedar.miden.io/account` | `https://explorer.devnet.miden.io/account` | (none) |

Each entry carries the chain's own network id, which decides an address's bech32
prefix, and whether real funds are at stake, which gates the blocking risk
notice.

The mainnet endpoints were read from the partner network on 2026-10-22. The
registry id, the pool code commitment, and the protocol fee recipient are
deployed per network and are not network defaults.

## Alpha notice

Each page shows the text of the selected network and, on mainnet, opens a
blocking acknowledgement modal on the first visit. Acceptance is stored under
`port0-app:alpha-risk:v1:<network>`. The modal and the strip link to the
[Terms of Service](../legal/terms.md); the alpha facts are in the
[closed alpha notice](alpha-risk.md), and the
[Privacy Policy](../legal/privacy.md) lists the stored keys.

## Protocol fee recipient

There is no app-side fee recipient. The destination is `protocol_fee_to` in the
registry, which a pool reads over FPI when it collects, so the address is set once
at registry creation and the app cannot disagree with it. The create page reads the
registry's fee policy and builds the pool with the registry's rate; the only gate
on creating a pool is a connected wallet.

## Registry

`VITE_REGISTRY_ID` accepts a hex account id or a bech32 address. When set, the
create flow emits a register note after the pool is deployed. The register note
is a network note consumed by the registry account, so registration is
asynchronous: the wallet confirms emission and the node's transaction builder
consumes the note in a later block. The register price comes from the registry's
own fee schedule, read at creation time, so an admin change needs no rebuild.

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
