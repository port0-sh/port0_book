# Privacy Policy

Last updated: 2026-10-24.

This policy covers the web interface at https://port0.sh (the "Interface"). It
does not cover the Miden network, your wallet software, or any third-party
service the Interface contacts.

## 1. What the Interface stores in your browser

The Interface uses browser local storage, not cookies. No cookie is set, and no
tracking pixel, analytics script, advertising identifier, or telemetry is
present. Nothing stored is sent to the project.

| Key | Purpose | Contents |
| --- | --- | --- |
| `port0-app:wallet-session:v1` | reconnect the wallet after a reload | wallet account id and public key |
| `port0-app:last-wallet-tx:v1` | follow the last wallet transaction | transaction id |
| `port0-app:create-draft:v1` | keep a half-filled pool creation form | the values you typed |
| `port0-app:sound:v1` | remember the sound setting | `on` or `off` |
| `port0-app:alpha-risk:v1:<network>` | remember acceptance of the alpha notice | `1` |

These values stay on your device and are readable by any script served from this
origin. Clearing site data removes all of them.

## 2. What leaves your browser

The Interface talks to the network from your browser, so the service sees you,
not the project.

| Destination | When | What it can see |
| --- | --- | --- |
| Miden node (RPC) | every chain read and every submitted transaction | your IP address, the accounts and notes you query, and the transactions you submit |
| Transaction prover | when a transaction is proved remotely | the transaction witness, which contains the account data needed to prove it |
| Note transport | when a private note is delivered | the note and its delivery address |
| Pool indexer, operated by this project | when browsing pools or opening a pool page | your IP address and the request; the indexer serves public chain state |
| Block explorer | only when you follow a link | your IP address, at the explorer |

The RPC endpoint, the prover, the note transport, and the explorer are operated
by Miden and its partners, not by this project. Their own terms and privacy
policies apply. The Interface can be pointed at other endpoints by whoever
builds it; the current build's endpoints are listed in
[App configuration](../app/configuration.md).

## 3. Blockchain data

Accounts and notes created as public are visible to everyone and are retained by
the network permanently. Transactions and the addresses involved can be
correlated now or later by any party, including with data from other sources.
Data written to the chain cannot be deleted or corrected. This is a property of
the network, not of the Interface.

## 4. Server logs

The Interface is served as static files, and the application code keeps no
request log. A deployment can run a reverse proxy in front of it that keeps
standard request logs, which hold the IP address, the time, and the requested
path; where such logs exist, their retention is set by that deployment. The pool
indexer application does not log request addresses: its own logs contain pool
and block counts.

## 5. Email

If you write to [hello@port0.sh](mailto:hello@port0.sh), the project sees the
address you send from and what you write, and keeps both only as long as needed
to answer. Requests about that correspondence go to the same address.

## 6. Your choices

- Clear site data for this origin to remove every stored value listed in
  section 1.
- Point the build at your own Miden node to keep chain reads away from a
  third-party RPC endpoint.
- Use a wallet you trust; the wallet is separate software with its own policy.

## 7. Children

The Interface is not directed at anyone below the age of majority, and the
closed alpha is offered only to adults who can enter a binding agreement.

## 8. Changes

A revised version appears at this address and carries its date. The version in
force is the one published here.

## 9. Contact

Email [hello@port0.sh](mailto:hello@port0.sh).
