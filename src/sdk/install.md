# Install

The SDK is published as `@port0.sh/sdk`.

```sh
npm install @port0.sh/sdk @miden-sdk/miden-sdk@0.17.1
```

The SDK peers on `@miden-sdk/miden-sdk` and is developed and tested against
`0.17.1`. Pin the exact version the testnet runs. A client talks only to a node
with the same major and minor version, so the two move together.

## Artifacts

The package embeds the eight compiled Miden packages from the contracts
repository: the pool and registry account components, and the mint, burn, swap,
collect, register, and registry-collect note scripts. `CONTRACT_SHA256` holds
the digest of each package for build-time drift detection.

## Source

The canonical source is the Radicle repository. GitHub and npm are mirrors. The
[repositories chapter](../reference/repositories.md) lists every location.
