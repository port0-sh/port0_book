# Contracts overview

The contracts repository contains eleven contracts: three [account
components](https://docs.miden.xyz/builder/smart-contracts/accounts/) and eight
[note scripts](https://docs.miden.xyz/builder/smart-contracts/notes/).

| Contract | Kind | Purpose |
| --- | --- | --- |
| `port0` | account component | Pool: reserves accounting, LP supply, fee rates, protocol pot, price oracle |
| `pool-registry` | account component | Accepted pool code commitments, pool set, asset pair index, protocol fee policy, expected pool storage roots, register fee admin |
| `network-faucet` | account component | Fixed-supply token faucet: immutable owner, one launch, supply accounting |
| `mint-note` | note script | Add liquidity |
| `burn-note` | note script | Remove liquidity |
| `swap-note` | note script | Trade |
| `collect-note` | note script | Move a pool's accrued protocol fees to the protocol account |
| `register-note` | note script | Register a pool in the registry |
| `registry-collect-note` | note script | Move the registry's whole balance to the protocol account |
| `registry-config-note` | note script | Change the registry's register fee, admin only |
| `launch-note` | note script | Mint a network faucet's whole supply to a recipient, once |

## Pool account components

A deployed pool account carries four components:

| Component | Purpose |
| --- | --- |
| `port0` | Reserves accounting, LP supply, fee rates, protocol pot, and oracle |
| Basic fungible faucet | LP token name, symbol, and decimals, so wallets render it |
| `CodeInspection` | `get_code_commitment`, which the registry reads over FPI at registration |
| Network auth | Note-script allowlist and fee schedule, plus `get_auth_identity` and `get_fee_identity` |

The registry pins the auth and fee storage roots at registration, because the
code commitment covers code and not storage. The SDK installs all four
components.

The repository layout:

```
contracts/
  port0/                    pool account component
  pool-registry/            registry account component
  mint-note/                add-liquidity note script
  burn-note/                remove-liquidity note script
  swap-note/                swap note script
  collect-note/             pool protocol-fee collection note script
  register-note/            pool registration note script
  registry-collect-note/    registry fee collection note script
  registry-config-note/     register fee configuration note script
  network-faucet/           fixed-supply token faucet component
  launch-note/              network faucet launch note script
integration/                MockChain integration tests and deployment binaries
```

## Pool lifecycle

1. Build the pool account. Its initial storage holds the token0 and token1 asset
   keys, the two fee parameters, the P2ID root, and the registry pointer. The LP
   token key is derived from the pool's account id and is not stored.
2. Fund the pool with a note and consume that note as the pool's first
   transaction. A network account requires every transaction to have an effect,
   so an empty scriptless deploy is rejected. The funding note commits the
   account and pays its first transaction fee from the received funds.
3. Emit the register note. The registry verifies the pool's code commitment and
   identity by foreign procedure invocation, then records the pool and its asset
   pair.
4. Liquidity providers emit mint notes and burn notes. Traders emit swap notes.
5. The fee recipient emits collect notes against a pool, or registry-collect
   notes against the registry. Both are permissionless.

## Execution model

Notes invoke pool procedures through the component interface. Pool procedures
run in account context and may create output notes and move assets. Note scripts
run in note context and may not perform those actions directly.

A pool's fee parameters, P2ID root, registry pointer, and token keys are initial
storage and hold for the pool's lifetime. No pool parameter is settable after
creation.

## Asset model

The LP token is a fungible asset issued by the pool account. No separate faucet
account exists. The asset key is derived from the pool's account id as
`[0, 0, suffix | 0x11, prefix]`, because the key embeds the account id and the
account id is derived from the initial storage commitment, so seeding it would
be circular.

## Build and test

Each contract is a standalone crate built with cargo-miden:

```sh
cargo miden build --manifest-path contracts/port0/Cargo.toml --release
```

The integration tests run against MockChain, an in-process chain that compiles
the contracts and executes the note flows without a network:

```sh
cargo test -p integration --release
```

The SDK's artifact exporter builds the packages itself. A manual build is needed
only to seed a fresh checkout.
