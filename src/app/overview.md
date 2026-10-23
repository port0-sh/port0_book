# App overview

The app is a static web application. Each page is a real HTML document with its
own metadata, its own module entry, and a minimal amount of TypeScript. There is
no application framework and no client-side page router. A separate swap router
ranks multihop routes over the indexed pools.

| Route | File | Purpose |
| --- | --- | --- |
| `/` | `index.html` | Browse every registered pool from the indexer |
| `/pool.html?id=<poolid>` | `pool.html` | Pool state, swap, add liquidity, remove liquidity |
| `/create.html` | `create.html` | Deploy a pool and register it |
| `/about.html` | `about.html` | What port0 is, and the risk notice |
| `/utils.html` | `utils.html` | One-time mint, registry admin, and send public note |
| `/media.html` | `media.html` | Mark, wordmark, colors, type, and the unfurl image |

Every page carries the same parts: the alpha notice as a strip above the
header, the footer with the copyright year and the social links, and the chart
attribution. The strip shows the text of the selected network. On testnet it is
dismissible, and the dismissal is remembered under
`port0-app:alpha-risk:v1:testnet`. On mainnet the strip is permanent and the
first visit is gated by a modal that records acceptance under
`port0-app:alpha-risk:v1:mainnet`; the
[closed alpha risk notice](alpha-risk.md) carries the terms. The index
adds the hero drawing, the brand heading under it, a link to the launch page,
and the slogan.

Pool ids are canonical account-id hex strings with or without a `0x` prefix.

## Pool list

The home page loads every pool the indexer serves, in indexer pages of 200, and
polls every 15 s while the tab is visible. Each row carries the pair and its
short pool id, the price of one token0 in token1, both reserves, 24-hour volume
in both tokens, the LP fee, and the fee yield on a 24 h basis.

Filtering, sorting, and paging run in the browser over the loaded set, so neither
a filter nor a sort makes another request. The filter matches a symbol, a pair,
or a faucet id. Sorting is by volume descending by default, and any column can be
sorted in either direction. The pager offers 10, 25, or 50 rows, defaulting to
10, and remembers the choice.

The list needs no chain read and no WASM. Prices come from the indexer's
reserves through the same exact bigint arithmetic the pool page uses. The swap
card executes through the SDK, which loads on the first swap.

## Swap card

The home page also carries a swap card. It quotes over the indexed pools without
loading the WASM client, then executes hop by hop through the wallet.

The router enumerates routes up to three hops over distinct tokens. Two pools
cannot serve the same pair, because the registry rejects a duplicate, so each
hop has exactly one pool. A route is ranked by output, with the direct pool
preferred at equal output. The quote uses the indexer's last snapshot, so it is
a quote and not a guarantee.

Execution is one wallet transaction per hop. The pool consumes the swap note and
emits a P2ID note of the output token to the sender, so the intermediate asset
has to reach the wallet's vault before the next hop can spend it. The next hop's
input is the amount the wallet actually received, so a reserve shift between
hops changes only the final output. A failed hop reports its index, and a retry
resumes at that hop. Each hop carries its own slippage bound.

## Pool page

The pool page renders the state summary, the swap, add-liquidity, and
remove-liquidity forms, and the indexer's sampled history. A pool is absent from
the indexer between its registration transaction and the next registry poll, so
the page waits instead of failing: it shows a spinner banner, re-fetches every
5 s, and loads the pool when it appears. After a minute it states that a pool
which was never registered will not appear. While the page is open, pool
metadata and history are re-read every 60 s.

A confirmed action does not change the visible state immediately. The wallet
confirms at its own block, the pool account changes in the next block, and the
indexer samples within 15 s. After a swap, deposit, or withdrawal, the page
polls the chain state, wallet balances, the indexer record, and the history
every 5 s for up to 60 s, and stops as soon as reserves or LP supply change.

History comes from `GET /pools/{id}/history` at 1m, 5m, 1h, 6h, or 1d
resolution and is drawn as candlesticks with a crosshair, a price line, and a
last-value label. The chart library is the largest dependency in the app and
only this page uses it, so it is imported on demand.

The pool page leads with the current price of one token0 in token1, computed by
the contract's own formula against the chain state. Until the first chain read
returns, the headline is filled from the indexer's reserves with the same ratio
arithmetic.

## Pool operations

All pool actions are notes to the pool account. The app builds the note and its
FEE_SPONSORSHIP note through the SDK with `submit: false`, then hands the
resulting `TransactionRequest` to the connected wallet, which signs, submits,
and reports confirmation.

Quoting is local and exact: the SDK's contract math runs against the latest
fetched pool state. Slippage is a basis-point bound in `[0, 9999]`. Deadlines
are the maximum of the wall clock and the pool's last-seen block timestamp, plus
one hour.

The deploy step of pool creation is an exception: the pool is a network account
without a key. The wallet sends a small chain fee asset note to the pool
address, and the app's own client consumes that note as the pool's first
transaction, which commits the account and pays its first fee. There is no
scriptless deploy, because the network auth rejects a transaction with no
effect.

## Branding

The name and slogan are configuration. The two drawings are files.

| Item | Effect |
| --- | --- |
| `VITE_BRAND_NAME` | Wordmark, page titles, `og:site_name`, footer |
| `VITE_BRAND_MARK_TEXT` | Text form of the mark, used in page titles |
| `VITE_BRAND_LOGO_TEXT` | Text mark beside the header logo; falls back to the name |
| `VITE_BRAND_SLOGAN` | One line under the home page name; empty hides it |
| `VITE_BRAND_TAGLINE` | Unfurl title and image alt text |
| `VITE_BRAND_DESCRIPTION` | Unfurl description and manifest description |
| `VITE_BRAND_X_HANDLE` | X account, for `twitter:site` |
| `src/assets/branding/hero.html` | The home page hero |
| `src/assets/branding/logo.html` | The mark in the header of the other pages |

Both drawings are injected as they stand. A drawing may carry a `<style>`
element, which is where its own motion belongs.

## Build

```sh
npm install
npm run dev        # dev server; the node serves the CORS headers the browser needs
npm test           # vitest, pure-logic unit tests
npm run typecheck  # tsc --noEmit
npm run lint       # oxlint
npm run build      # tsc -b && vite build, output in dist/
npm run preview    # serve dist/ locally
```

The build output is plain static files: six HTML documents, one CSS file, one
small JS bundle per page, and a shared lazy chunk containing the Miden SDK.
