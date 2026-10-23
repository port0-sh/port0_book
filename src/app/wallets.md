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
account id. Pressing it opens a menu with one item, Disconnect.

## Sound

A completed swap rings a two-strike ship's bell. The sound is synthesized with
Web Audio, so nothing loads before the first swap, and the preference is one
localStorage key. A browser only allows audio after a user gesture, so the audio
context is opened on the swap click.

## Utils page

The chain utilities live on their own page at `/utils.html`, in the top
navigation. No wallet is needed to read the page. All three tools act through a
wallet, so their buttons stay disabled until one connects.

| Utility | What it does |
| --- | --- |
| One-time mint | Creates a network faucet whose whole supply is minted once to the wallet by a launch note, with `maxSupply` equal to that supply and an immutable owner. Nothing can be minted afterwards. |
| Registry admin | Changes the registry's register fee. It reads the admin and the live fee from chain, refuses a wallet that is not the admin, and emits a `registry-config` note. No sponsorship is attached: the registry prices that note at zero. |
| Send public note | Sends the chain fee asset through the wallet's own `requestSend` with a public note type, the only path that can target an account that does not exist on chain yet. |

Each tool builds its form in a modal.
