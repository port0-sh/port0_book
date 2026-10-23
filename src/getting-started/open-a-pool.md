# Open a pool

A token with no market acquires one in about ten minutes. This chapter covers the
whole flow, from holding a token to holding a pool that trades.

## What the flow requires

1. A wallet the app can connect to, holding USDCX.
2. A token. When none exists, the Utils page mints one in the next section.
3. Nothing else. There is no application and no approval.

## 1. Acquire USDCX

Every transaction on Miden pays a fee in the chain's fee asset. On testnet that
asset is USDCX, issued by the faucet at
[faucet.testnet.miden.io](https://faucet.testnet.miden.io). The faucet takes a
wallet address, sends a public note, and the wallet turns the note into a
spendable balance.

USDCX pays the network fees for every step below. The pool does not require USDCX
as the second side of the trade: any two tokens can form a pair.

## 2. Mint a token, when none exists

The One-time mint tool at [port0.sh/utils.html](https://port0.sh/utils.html)
creates a fixed-supply faucet and mints the whole supply to the wallet.

![The Utils page with the One-time mint panel outlined](utils.png)

| Field | Rule |
| --- | --- |
| Symbol | 3 to 12 uppercase letters. The protocol rejects digits |
| Name | Optional, up to 32 characters; empty uses the symbol |
| Decimals | 0 to 8 |
| Supply | The whole supply, minted in the same flow |

The faucet is created with `maxSupply` equal to the supply, so nothing remains to
mint afterwards and the whole supply lands in the wallet.

The faucet is a network account, so creating it needs no invitation code on a
gated network. The deploy is funded with 112 base units of USDCX, the measured
cost of a faucet deploy consume, and the launch that mints the supply is a second
transaction paid by the owner's wallet through a sponsorship of 119 base units.

## 3. Open the pool

The create page at [port0.sh/create.html](https://port0.sh/create.html) takes the
pair and the fee tier.

![The create page with the token fields, the fee tier, and the three deploy steps outlined](create.png)

| Field | Value |
| --- | --- |
| Token 0 | The new token |
| Token 1 | USDCX, or any second token |
| LP fee tier | 0.05 percent, 0.30 percent, or 1.00 percent |

Submission runs three steps in order.

| Step | What happens | Who pays |
| --- | --- | --- |
| Create the pool account | Built locally. The fee rates, the P2ID root, the registry pointer, and the LP token metadata are set at creation and hold for the pool's life | Nothing |
| Deploy | The wallet sends 133 base units of USDCX to the pool, and the app consumes that note as the pool's first transaction | The wallet |
| Register | A register note goes to the registry, which checks the pool's code commitment, its fee values, and the pair | The wallet, plus the registry's register fee |

The register fee on testnet is 119 base units of USDCX. The create page reads it
from the registry and shows it before submission.

When the third step lands, the page opens the pool's own page.

## 4. Provide liquidity

A pool with no reserves has no market. No trade can execute against it, and it
reads as an empty pair in the list.

The pool page takes both tokens as a deposit. The pool mints LP tokens in
proportion to the depositor's share. After the first deposit the pool has a
price, and a swap against it moves that price.

![A pool page with the price, the 24 hour stats, and the price history outlined](pool.png)

The first deposit sets the price. It should be made at the ratio the pair is
worth, because the market starts there.

## Cost

| Item | Base units of USDCX |
| --- | --- |
| Minting a token, when needed | 112 plus a 119 launch sponsorship |
| Deploying the pool | 133 |
| The register fee | 119 |
| Network fees per operation | About 119 per swap, about 112 per collect |

A pool created with an existing token costs the deploy and the register fee
only.

## After the pool exists

1. The registry holds the pool, and the indexer publishes it within about a
   minute. It appears in the list on the home page with its pair, its reserves,
   and its price.
2. The pool page carries the state, a chart, and the three actions: swap, add
   liquidity, remove liquidity.
3. Every swap pays the LP fee into the pool. Liquidity providers hold the LP
   token and share in that fee.
4. The protocol takes a share of the LP fee, fixed by the registry. The share is
   carved out of the LP fee rather than added to the swapper's cost, so the
   swapper pays the tier and nothing more.

## When a step fails

The create page keeps its state and offers **Retry** for the step that failed
and **Restart flow**. A retry resumes at the failed step, does not create a
second pool, and reuses the funding note the deploy step already sent.

A summary anchor mismatch at the register step means a block landed between two
reads. Retry rebuilds the request at the current block.

## What the pool is

The pool account is public. Its reserves, its history, and its fee rates are
readable by anyone. The network is a testnet whose tokens have no value.
