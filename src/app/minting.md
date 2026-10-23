# Token minting

A fixed-supply token is launched from the Utils page at `/utils.html`, with the
One-time mint tool. The faucet is a **network account**, so creating it needs no
invitation code on a network that gates keyed accounts. It is created with
`maxSupply` equal to the supply, and one launch mints that whole amount to the
caller's wallet and records it as the token's supply. Nothing remains to mint
afterwards, and the launch cannot be repeated. The faucet id can fill either
token field of the create page's pool form.

The owner is recorded at creation and is immutable: only that account's launch
note can mint, and it can do so once. The account installs no mint policy, so the
standard faucet component's own minting procedure is unreachable. A token that
needs ongoing minting is a different product and uses a regular faucet, which on
a gated network needs an allowlist entry.

## Funding

A fresh faucet has an empty vault and cannot pay the fee of its own first
transaction. The connected wallet sends it 112 base units, the measured cost of a
faucet deploy consume, and that transaction consumes the funding note, which
creates the faucet on chain. A faucet has no sweep, so the funding is exactly the
measured cost rather than a padded amount. The launch that follows is paid by the
owner's wallet through a fee sponsorship of 119 base units, the measured launch
note price. That price carries the pricer's one-cycle margin of 7 base units, so
the launch leaves exactly that behind: a faucet has no sweep, and the margin is
the price of never being one cycle short. The launch is a second
transaction, and the owner's wallet pays for it by emitting the launch note
together with a fee sponsorship, so the faucet's balance is not what pays it.

## Validation

| Field | Rule |
| --- | --- |
| Symbol | 3 to 12 uppercase ASCII letters. The protocol rejects digits, and its own cap is 12. |
| Name | Optional display name, up to 32 characters. Empty means the symbol is used; the protocol stores names as UTF-8 within 32 bytes, so accented or emoji names allow fewer characters |
| Decimals | Integer from 0 to 8 |
| Initial supply | Entered in tokens, bounded by `MAX_AMOUNT` of `2^57` base units |

The supply bound is the port0 contract's own limit: amounts are u64 with u128
intermediates and 10,000 bps fee headroom.

## Network note fees

Network note fees are denominated in the chain's fee asset, paid to the chain's
own fee faucet. The node never runs network transactions for an
account whose fee asset differs from the chain's protocol configuration, so the
app reads the faucet from the client instead of asking the user. The creator's
wallet must hold the chain fee asset to pay network note fees when acting on a
pool afterwards.
