# Wallets

The app wires Bread Wallet through `@miden-sdk/miden-wallet-adapter-miden`. The
wallet picker shows its detection state and opens the install page when the
extension is missing. Para Wallet's packages are installed, and the login
flow is gated behind `VITE_PARA_API_KEY`: without a configured key the picker
explains the dependency instead of failing later.

## Package versions

The package versions are pinned in the app manifest. Keep `@miden-sdk/*` and
`@port0.sh/sdk` on the versions the testnet runs; see the
[network chapter](../reference/network.md).

## Wallet menu

The header shows a Login button until a wallet connects. Afterwards it shows the
account id. Pressing it opens a menu whose Utils group holds two utilities and
whose last item disconnects.

| Utility | What it does |
| --- | --- |
| One-time mint | Creates a public faucet whose whole supply is minted to the wallet in one transaction, with `maxSupply` equal to that supply. Nothing can be minted afterwards. |
| Send public note | Sends the chain fee asset through the wallet's own `requestSend` with a public note type, the only path that can target an account that does not exist on chain yet. |

Both build their form in a modal, so no page carries a utility it does not need.
