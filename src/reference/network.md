# Network

port0.sh runs on [Miden](https://docs.miden.xyz/builder/) testnet 0.17.1.

| Fact | Value |
| --- | --- |
| Protocol and testnet version | 0.17.1 |
| RPC | `https://rpc.testnet.miden.io` (gRPC, `miden.node.v1.NodeService`) |
| Remote prover | `https://tx-prover.testnet.miden.io` |
| Chain fee faucet | `0x4cbdcaffe75f0a317482224dae6436` |
| Chain fee asset | USDCX, 6 decimals |
| Block time | about 3 seconds |
| Measured transaction fee | about 133 base units of USDCX |

## Version rule

A client talks only to a node of the same major and minor version. A stale minor
fails with errors that look like application bugs, such as a missing procedure
root, a null pointer passed to Rust, or a missing account header record. Pin
every `@miden-sdk/*` and `miden-node-proto` dependency to the exact version the
testnet runs, and bump them together.

| Package | Version |
| --- | --- |
| `@miden-sdk/miden-sdk` | 0.17.1 |
| `@miden-sdk/miden-wallet-adapter-base` | 0.17.0 |
| `@miden-sdk/miden-wallet-adapter-miden` | 0.17.0 |
| `@miden-sdk/para` | 0.17.0 |
| `@getpara/web-sdk` | 3.18.0 |
| `@port0.sh/sdk` | 0.1.0 |
| Guest `miden` SDK | 0.15.0 |
| `miden-protocol`, `miden-tx`, `miden-standards` | 0.17.1 |
| VM crates | 0.35.0 |

## Fees and notes

Notes carry a fee, and the executing account pays it from its own vault. A
pool's fee faucet must equal the chain's fee faucet, or the node never consumes
the pool's notes. USDCX comes from the network faucet. Do not mint it.

## Node state window

The node serves account state for the last 50 blocks. Anchors and block numbers
older than that fail with a pruned-block error. A network-note-emitting
transaction expires 20 blocks after its reference block, which is about one
minute, so slow proving can outrun the window.

## Numeric bound

Every pool amount, reserve, and `lp_supply` is bounded by `MAX_AMOUNT = 2^57`.
The bound keeps the u128 intermediates inside `u128::MAX`.
