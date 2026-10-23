# Network faucet

A launched token is a fixed-supply token whose faucet is itself a network
account. On a network that gates keyed accounts, a regular faucet needs an
allowlist entry before its first transaction; a network account is exempt, so
launching a token needs no invitation.

## Components

The faucet account carries three components.

| Component | Purpose |
| --- | --- |
| `network-faucet` | Immutable owner, launch flag, and the launch procedure |
| Basic fungible faucet | Name, symbol, decimals, and maximum supply, which a wallet reads |
| Network auth | Allowlists the launch note and prices it |

The standard faucet component is what makes a wallet recognize the account as a
faucet. Its own minting procedure stays unreachable because the account installs
no mint policy, and that procedure aborts without one.

## Storage

| Slot | Type | Encoding |
| --- | --- | --- |
| `owner` | Word | `[0, 0, suffix, prefix]` of the account allowed to launch |
| `launched` | Felt | `[flag, 0, 0, 0]`, `1` after the supply is minted |

Both are set at creation. The owner cannot be rotated and the flag cannot be
cleared.

## Launch

`launch(recipient, serial_num, tag)` performs the whole supply mint:

1. The launch note's sender must equal `owner`.
2. `launched` must be zero.
3. The maximum supply is read from the standard component's `token_config` slot
   and must be positive.
4. That amount is minted, paid to `recipient` as a P2ID note, and written back
   into `token_config` as the token supply.
5. `launched` is set to `1`.

A launch is one-way. There is no second mint, no supply change, and no owner
rotation. The amount minted is exactly the maximum the metadata advertises.

## Failure conditions

- The note sender differs from `owner`.
- The token has already been launched.
- The configured maximum supply is zero.

## Fees

The launch note is a network note, so it travels with a FEE_SPONSORSHIP note at
the measured schedule price, 119 base units at the current base fee. The owner's
wallet pays it. The sponsorship carries the pricer's one-cycle margin, and a
faucet has no sweep, so that margin stays in the faucet as its only balance.

The faucet's own first transaction is the deploy consume, funded with 112 base
units, the measured cost of that call shape.
