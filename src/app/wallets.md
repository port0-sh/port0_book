# Wallets

The app wires Bread Wallet through `@miden-sdk/miden-wallet-adapter-miden`. The
wallet picker shows its detection state and opens the install page when the
extension is missing. Para Wallet's 0.17 packages are installed, and the login
flow is gated behind `VITE_PARA_API_KEY`: without a configured key the picker
explains the dependency instead of failing later.

## Version matrix

| Package | Version |
| --- | --- |
| `@miden-sdk/miden-sdk` | 0.17.1 |
| `@miden-sdk/miden-wallet-adapter-base` | 0.17.0 |
| `@miden-sdk/miden-wallet-adapter-miden` | 0.17.0 |
| `@miden-sdk/para` | 0.17.0 |
| `@getpara/web-sdk` | 3.18.0 |
| `@port0.sh/sdk` | 0.1.0, pinned exactly |

## Wallet menu

The header shows a Login button until a wallet connects. Afterwards it shows the
account id. Pressing it opens a menu whose Utils group holds two utilities and
whose last item disconnects.

| Utility | What it does |
| --- | --- |
| One-time mint | Creates a public faucet whose whole supply is minted to the wallet in one transaction, with `maxSupply` equal to that supply. Nothing can be minted afterwards. |
| Send public note | Sends the chain fee asset through the wallet's own `requestSend` with a public note type, the only path that can target an account that does not exist on chain yet. |

Both build their form in a modal, so no page carries a utility it does not need.
