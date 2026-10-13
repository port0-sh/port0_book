# Glossary

The Miden documentation is the authority for Miden terms:
[Reference](https://docs.miden.xyz/reference/) and
[Builder](https://docs.miden.xyz/builder/). The entries below state how the
terms are used in this book.

| Term | Meaning | Miden reference |
| --- | --- | --- |
| AMM | Automated market maker. A contract that prices an asset pair from its reserves. | |
| XYK | The constant-product invariant `x * y = k`. | |
| Berth | A pool. A single account holding two assets. | |
| Manifest | The registry. The account that holds the accepted pool code commitments and the pool set. | |
| Cargo | A token. A fungible asset held or traded by a pool. | |
| Crew | Liquidity providers. The accounts that deposit both assets and hold LP tokens. | |
| Account | A unit of Miden state holding storage, code, and a vault. | [Accounts](https://docs.miden.xyz/reference/protocol/account/) |
| Account component | Code installed on an account. | [Accounts](https://docs.miden.xyz/builder/smart-contracts/accounts/) |
| Faucet | An account that issues a fungible asset. | [Assets](https://docs.miden.xyz/reference/protocol/asset) |
| Note | A Miden message carrying a script, storage, and assets to a target account. | [Notes](https://docs.miden.xyz/reference/protocol/note) |
| Note script | The code a note runs. | [Notes](https://docs.miden.xyz/builder/smart-contracts/notes/) |
| Transaction | The execution that consumes notes and updates accounts. | [Transactions](https://docs.miden.xyz/reference/protocol/transaction) |
| MASM | Miden assembly, the language the contracts compile to. | [MASM](https://docs.miden.xyz/builder/smart-contracts/masm/) |
| LP token | The fungible asset a pool issues to represent a share of its reserves. | |
| LP fee | The fee a swapper pays, in basis points of the input. | [Fees](https://docs.miden.xyz/reference/protocol/fees) |
| Protocol share | The registry's share of the LP fee, in basis points of that fee. | [Fees](https://docs.miden.xyz/reference/protocol/fees) |
| Registry share | See protocol share. | |
| LP fee tier | One of the allowed `lp_fee_bps` values the registry lists. | |
| Protocol pot | The pool's accrued protocol fees, held in the vault until collected. | |
| Network account | An account serviced by the node's transaction builder through a note-script allowlist, with no signing key. | [Network](https://docs.miden.xyz/builder/tools/network) |
| Network note | A note carrying a `NetworkAccountTarget` attachment, so the node can route it to a network account. | [Notes](https://docs.miden.xyz/builder/smart-contracts/notes/) |
| FEE_SPONSORSHIP | The note that carries a feature note's consumption fee and is consumed with it. | [Fees](https://docs.miden.xyz/reference/protocol/fees) |
| P2ID | The pay-to-id note script used for output notes. | [Notes](https://docs.miden.xyz/builder/smart-contracts/notes/) |
| FPI | Foreign procedure invocation. A call from one account's procedure into another account's procedure. | [Cross-component calls](https://docs.miden.xyz/builder/smart-contracts/cross-component-calls) |
| Slippage | The difference between a quoted output and the accepted minimum. | |
| Deadline | A block timestamp after which a note reverts. | |
| `MAX_AMOUNT` | The u64 cap `2^57` on every reserve, amount, and `lp_supply`. | |
| `MINIMUM_LIQUIDITY` | The 1000 LP tokens locked permanently on the first mint. | |
| Oracle | The two cumulative price accumulators and the last update timestamp. | |
| Collect | The operation that moves a protocol pot or a registry balance to the protocol account. | |
