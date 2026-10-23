# Network

port0.sh runs on [Miden](https://docs.miden.xyz/builder/). Two networks are
supported: the public testnet and the Miden partner mainnet. The version a
network runs is published at
[status.testnet.miden.io](https://status.testnet.miden.io/).

| Fact | testnet | mainnet |
| --- | --- | --- |
| RPC | `https://rpc.testnet.miden.io` | `https://rpc.cedar.miden.io` |
| Remote prover | `https://tx-prover.testnet.miden.io` | `https://tx-prover.cedar.miden.io` |
| Note transport | `testnet` | `https://transport.cedar.miden.io` |
| Chain fee faucet | `0x4cbdcaffe75f0a317482224dae6436` | `0xe69e6ca6e39df1b10c1e5399399feb` |
| Explorer | `https://testnet.midenscan.com/account` | `https://explorer.cedar.miden.io/account` |

Both endpoints speak gRPC (`miden.node.v1.NodeService`). The chain fee asset is
USDCX, 6 decimals. Block time is about 3 seconds.

| Fee fact | Value |
| --- | --- |
| Base fee (`verification_base_fee`) | 7 base units |
| Maximum transaction fee | 210 base units (`7 x 30`) |
| Pool note schedule price | 126 base units (`mint`, `burn`, `swap`, `collect`) |
| Registry note schedule price | 119 base units (`register`, `registry-collect`) |
| Measured swap transaction | about 119 base units |
| Measured collect transaction | about 112 base units |

## Version rule

A client talks only to a node of the same major and minor version. A stale minor
fails with errors that look like application bugs, such as a missing procedure
root, a null pointer passed to Rust, or a missing account header record.

Pin every `@miden-sdk/*` and `miden-node-proto` dependency to the version the
network runs, and bump them together. The manifests carry the current pins:
`package.json` and `package-lock.json` in the SDK and the app, `Cargo.toml` and
`Cargo.lock` in the contracts and the indexer.

## Fees and notes

Notes carry a fee, and the executing account pays it from its own vault. The
emitter prepays it with a FEE_SPONSORSHIP note, at the schedule price for the
note kind. The remainder stays with the account and a later collect sweeps it.
A pool's fee faucet must equal the chain's fee faucet, or the node never consumes
the pool's notes. The fee asset comes from the network faucet. Do not mint it.

## Node state window

The node serves account state for the last 50 blocks. Anchors and block numbers
older than that fail with a pruned-block error. A network-note-emitting
transaction expires 20 blocks after its reference block, which is about one
minute, so slow proving can outrun the window.

## Numeric bound

Every pool amount, reserve, and `lp_supply` is bounded by `MAX_AMOUNT = 2^57`.
The bound keeps the u128 intermediates inside `u128::MAX`.
