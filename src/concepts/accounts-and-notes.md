# Accounts and notes

Miden state is held in [accounts](https://docs.miden.xyz/reference/protocol/account/)
and moved by [notes](https://docs.miden.xyz/reference/protocol/note). Every port0
operation is a note that targets an account.

## Accounts

Three account kinds appear in the system:

| Kind | Role |
| --- | --- |
| Wallet | Holds assets and signs transactions |
| [Faucet](https://docs.miden.xyz/reference/protocol/asset) | Issues a fungible asset |
| Contract | Runs [account-component](https://docs.miden.xyz/builder/smart-contracts/accounts/) code against its own storage and vault |

A public account stores its full state on chain. A private account stores only a
commitment on chain and keeps the state with its holder. A pool is a public
account: its reserves, LP supply, fee rates, and oracle readings are readable by
anyone.

An account id is two field elements, prefix and suffix, and renders as
0x-prefixed hex or as a bech32 address.

## Network accounts

A [network account](https://docs.miden.xyz/builder/tools/network) installs the
network-account auth component. The component carries a note-script allowlist,
the fee policy, and the nonce handling, and the node's transaction builder reads
the allowlist to consume notes on the account's behalf. No signing key is
involved. Removing the component turns the account into an ordinary account the
node does not service.

Every transaction executed by a network account must have an effect: an input
note, an output note, or an account state change. An empty scriptless
transaction is rejected. A new network account is therefore committed by
consuming a funding note as its first transaction, which also pays the first
transaction fee from the received funds.

Both the pool and the registry are network accounts.

## Notes

A [note](https://docs.miden.xyz/reference/protocol/note) carries a script,
storage, and assets. The [script](https://docs.miden.xyz/builder/smart-contracts/notes/)
runs in note context and calls an account procedure through the component
interface. Note scripts may not create output notes or move assets directly;
account procedures may.

| Visibility | Behavior |
| --- | --- |
| Public | Published on chain and discoverable by the target through chain sync |
| Private | Encrypted and delivered to the target through note transport |

A port0 feature note is a public [network
note](https://docs.miden.xyz/builder/smart-contracts/notes/): it carries a
`NetworkAccountTarget`
attachment bound to the target account, so the node's transaction builder can
route it. Each feature note travels with a separate FEE_SPONSORSHIP note that
pays the target's configured note consumption fee.

## Note fees

Notes carry a [fee](https://docs.miden.xyz/reference/protocol/fees). A fee asset
is required to consume a note, and the executing
account pays it from its own vault. A pool's fee faucet must equal the chain's
fee faucet, or the node never consumes the pool's notes. On the Miden testnet
the chain fee asset is USDCX. It comes from the network faucet; it is not
minted by this project.

The registry prices its note kinds in its network auth at the schedule price,
119 base units for the register and registry-collect notes, so their
sponsorships cover the actual transaction fee. It prices the admin's config note
at zero, because the registry pays that fee from the register fees it holds. The
registry's `collect` also leaves the transaction's own fee reserve in its vault
when the transaction is not sponsored.

## Output notes and foreign calls

An account procedure can create output notes, which is how a pool returns LP
tokens, refunds, swap output, and collected fees. Output notes use the
[P2ID](https://docs.miden.xyz/builder/smart-contracts/notes/) script by default,
with the recipient and the pool's stored P2ID root.

A pool reads its protocol fee destination from the registry by [foreign
procedure
invocation](https://docs.miden.xyz/builder/smart-contracts/cross-component-calls).
The registry reads a pool's code commitment and identity the same
way at registration. The registry holds the protocol fee destination once for
every pool, and it is read only on the collect path.
