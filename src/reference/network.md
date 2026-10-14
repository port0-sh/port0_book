# Network

port0.sh runs on [Miden](https://docs.miden.xyz/builder/) testnet.

| Fact | Value |
| --- | --- |
| RPC | `https://rpc.testnet.miden.io` (gRPC, `miden.node.v1.NodeService`) |
| Remote prover | `https://tx-prover.testnet.miden.io` |
| Chain fee faucet | `0x4cbdcaffe75f0a317482224dae6436` |
| Chain fee asset | USDCX, 6 decimals |
| Block time | about 3 seconds |
| Base fee (`verification_base_fee`) | 7 |
| Maximum transaction fee | 210 base units of USDCX (`7 x 30`) |
| Measured swap transaction fee | about 119 base units of USDCX |
| Measured collect transaction fee | about 112 base units of USDCX |

## Version rule

A client talks only to a node of the same major and minor version. A stale minor
fails with errors that look like application bugs, such as a missing procedure
root, a null pointer passed to Rust, or a missing account header record.

Pin every `@miden-sdk/*` and `miden-node-proto` dependency to the version the
testnet runs, and bump them together. The manifests carry the current pins:
`package.json` and `package-lock.json` in the SDK and the app, `Cargo.toml` and
`Cargo.lock` in the contracts and the indexer.

## Fees and notes

Notes carry a fee, and the executing account pays it from its own vault. The
emitter prepays it with a FEE_SPONSORSHIP note; every pool note kind is priced
at the protocol maximum so the prepayment always covers the charge. The
remainder stays with the account and a later collect sweeps it. A pool's fee
faucet must equal the chain's fee faucet, or the node never consumes the pool's
notes. USDCX comes from the network faucet. Do not mint it.

## Node state window

The node serves account state for the last 50 blocks. Anchors and block numbers
older than that fail with a pruned-block error. A network-note-emitting
transaction expires 20 blocks after its reference block, which is about one
minute, so slow proving can outrun the window.

## Numeric bound

Every pool amount, reserve, and `lp_supply` is bounded by `MAX_AMOUNT = 2^57`.
The bound keeps the u128 intermediates inside `u128::MAX`.
