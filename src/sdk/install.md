# Install

The SDK is published as `@port0.sh/sdk`.

```sh
npm install @port0.sh/sdk @miden-sdk/miden-sdk
```

The SDK peers on `@miden-sdk/miden-sdk`. Pin the version the testnet runs; a
client talks only to a node with the same major and minor version. The
manifests in each repository carry the current pins.

## Artifacts

The package embeds the eight compiled Miden packages from the contracts
repository: the pool and registry account components, and the mint, burn, swap,
collect, register, and registry-collect note scripts. `CONTRACT_SHA256` holds
the digest of each package for build-time drift detection.

## Source

The canonical source is the Radicle repository. GitHub and npm are mirrors. The
[repositories chapter](../reference/repositories.md) lists every location.
