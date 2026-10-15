# App overview

The app is a static web application. Each page is a real HTML document with its
own metadata, its own module entry, and a minimal amount of TypeScript. There is
no application framework and no client-side router.

| Route | File | Purpose |
| --- | --- | --- |
| `/` | `index.html` | Browse every registered pool from the indexer |
| `/pool.html?id=<poolid>` | `pool.html` | Pool state, swap, add liquidity, remove liquidity |
| `/create.html` | `create.html` | Deploy a pool and register it |
| `/about.html` | `about.html` | What port0 is, and the risks of a testnet |
| `/utils.html` | `utils.html` | One-time mint and send public note |
| `/media.html` | `media.html` | Mark, wordmark, colors, type, and the unfurl image |

Every page carries the same parts: the testnet notice as a strip above the
header, dismissed once and remembered under the key that `<html data-notice-key>`
names, the footer with the copyright year and the social links, and the chart
attribution. The index
adds the hero drawing, the brand heading under it, a link to the launch page,
and the slogan.

Pool ids are canonical account-id hex strings with or without a `0x` prefix.

## Pool list

The home page lists the pools the indexer serves, 50 per page, polled every 15 s
while the tab is visible. Each row carries the pair and its short pool id, the
price of one token0 in token1, both reserves, 24-hour volume in both tokens, the
LP fee, and the fee yield with the window it is annualised over. Rows are
ordered by pair name so a row keeps its place between refreshes. A filter
accepts a faucet id, and the Load more control walks the indexer's keyset
cursor.

The page needs no chain read and no WASM. Prices come from the indexer's
reserves through the same exact bigint arithmetic the pool page uses.

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
| `VITE_BRAND_LOGO_TEXT` | Text mark beside the header logo; falls back to the name |
| `VITE_BRAND_SLOGAN` | One line under the home page name; empty hides it |
| `src/assets/branding/hero.html` | The home page hero |
| `src/assets/branding/logo.html` | The mark in the header of the other pages |

Both drawings are injected as they stand. A drawing may carry a `<style>`
element, which is where its own motion belongs.

## Build

```sh
npm install
npm run dev        # dev server with same-origin gRPC-web RPC proxy
npm test           # vitest, pure-logic unit tests
npm run typecheck  # tsc --noEmit
npm run lint       # oxlint
npm run build      # tsc -b && vite build, output in dist/
npm run preview    # serve dist/ locally
```

The build output is plain static files: four HTML documents, one CSS file, one
small JS bundle per page, and a shared lazy chunk containing the Miden SDK.
