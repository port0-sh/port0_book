# Token minting

A fixed-supply token is minted from the Utils page at `/utils.html`, with the
One-time mint tool. The faucet is created with `maxSupply` equal to the initial
supply, and the whole supply is minted to the caller's wallet. Nothing remains
to mint afterwards. The faucet id can fill either token field of the create
page's pool form.

## Funding

A fresh faucet has an empty vault and cannot pay the fee of its own first
transaction. The connected wallet sends 0.000266 USDCX to the new faucet, which
is exactly the two transaction fees it will pay: consume and mint, at 2 x 133
base units, the measured testnet fee. The faucet's first transaction consumes
that note, which creates the faucet on chain and pays its fee out of the
received funds. The supply mint follows as the second transaction.

## Validation

| Field | Rule |
| --- | --- |
| Symbol | 3 to 12 uppercase ASCII letters. The protocol rejects digits, and its own cap is 12. |
| Name | Optional display name, up to 32 characters. Empty means the symbol is used; the protocol stores names as UTF-8 within 32 bytes, so accented or emoji names allow fewer characters |
| Decimals | Integer from 0 to 8 |
| Initial supply | Entered in tokens, bounded by `MAX_AMOUNT` of `2^57` base units |

The supply bound is the AMM contract's own limit: amounts are u64 with u128
intermediates and 10,000 bps fee headroom.

## Network note fees

Network note fees are denominated in the chain's fee asset, paid to the chain's
own fee faucet. The node never runs network transactions for an
account whose fee asset differs from the chain's protocol configuration, so the
app reads the faucet from the client instead of asking the user. The creator's
wallet must hold the chain fee asset to pay network note fees when acting on a
pool afterwards.
