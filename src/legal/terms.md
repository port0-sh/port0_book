# Terms of Service

Last updated: 2026-10-24.

These Terms of Service (the "Terms") govern access to and use of the web
interface at https://port0.sh (the "Interface"). The Interface is one way to
reach the port0 protocol contracts on the Miden partner mainnet. By accessing or
using the Interface, you agree to these Terms. If you do not agree, do not use
the Interface.

## 1. Roles

| Actor | What it is | What it controls |
| --- | --- | --- |
| The Interface | The web application at port0.sh, published by the port0.sh project ("we", "us") | Presentation and request building |
| The contracts | Pool accounts, the pool registry, and faucets deployed on Miden | Deposits, swaps, and withdrawals, under their own code |
| The registry admin | An account fixed when the registry was created | The fee charged for registering a pool, and nothing else |
| The protocol fee recipient | An account fixed when the registry was created | The protocol's share of the LP fee |
| The Miden network | Nodes, provers, and validators operated by Miden and its partners | Execution, finality, and the network fee |

The Interface is non-custodial. It holds no assets, no keys, and no seed
phrase, and it cannot move funds. A pool is a network account with no signing
key, no admin slot, and no upgrade path; its code and storage are fixed at
deployment. The project controls no pool and no registry.

## 2. Eligibility

To use the Interface you represent that:

- you have the legal capacity to enter a binding agreement and are at least the
  age of majority in your jurisdiction;
- you are not the subject of sanctions administered or enforced by any
  government, and you are not resident in a jurisdiction where use would be
  unlawful;
- your use complies with the laws that apply to you.

The Interface does not verify identity and does not perform KYC. That does not
exempt you from any obligation the law places on you.

## 3. Your responsibilities

- **Keys.** Your wallet holds your keys. No contributor asks for a private key
  or a seed phrase. A lost key loses the funds, and no party can recover them.
- **Tokens.** Registration is permissionless and nothing is vetted. Determine
  what the token's faucet can do before you deposit. A creator can register a
  faucet that mints without limit and drain the other side of a pool.
- **Taxes.** You determine and pay the taxes that apply to your activity.
- **Compliance.** You are responsible for your own compliance with law.

## 4. Risks

The full statement is the [closed alpha notice](../app/alpha-risk.md). In
summary:

- Deposits can be lost in full. The contracts are unaudited.
- Transactions are irreversible. There is no refund, chargeback, or recovery.
- A pool can lose value, and a contract defect can lock or drain deposits.
- A listed token can be worthless, mintable without limit, or fraudulent.
- The network can halt, change its fee parameters, or, on testnet, be reset.
- The Interface can be wrong or lag the chain. The chain is authoritative.

## 5. Costs

Network fees are paid to the Miden network in its fee asset and are not
refundable. The protocol fee is a share of the LP fee, not an additional charge;
[Fees](../contracts/fees.md) carries the formula and the current values. The
Interface charges nothing else. Fee parameters, including the register fee, can
change.

## 6. No advice, no fiduciary duty

Nothing in the Interface or its documentation is financial, investment, legal,
or tax advice. No contributor is your broker, dealer, exchange, custodian, or
fiduciary, and no contributor owes you a duty of care in connection with the
Interface.

## 7. No warranty

The Interface and the accompanying software are provided "as is" and "as
available", without warranty of any kind, express or implied, including
merchantability, fitness for a particular purpose, title, and non-infringement.
No contributor warrants that the software is free of defects, that a transaction
executes as intended or at an expected price, that a listed token has value,
that displayed data matches the chain, or that access is uninterrupted. Where an
implied warranty cannot be excluded, it is limited to the shortest period the
law allows.

## 8. Limitation of liability

To the maximum extent permitted by law, the port0.sh project and its
contributors are not liable for any loss or damage arising from or related to
the Interface, the contracts, or the SDK, including loss of funds, loss of
profit, loss of data, and any direct, indirect, incidental, special,
consequential, or punitive damages, whether the claim sounds in contract, tort,
or otherwise, and whether or not a contributor was advised of the possibility of
such damage. This section does not limit liability that applicable law does not
permit to be limited.

## 9. Indemnification

You agree to indemnify and hold harmless the port0.sh project and its
contributors from any claim, loss, liability, or expense, including reasonable
legal fees, arising from your use of the Interface, your breach of these Terms,
or your violation of law or of a third party's rights.

## 10. Intellectual property

The source code of the Interface, the contracts, and the SDK is published under
the license stated in each repository. The name "port0" and its logo are
reserved; no license to use them is granted by these Terms or by the code
license.

## 11. Third-party services

The Interface sends requests to third-party services: a Miden node (RPC), a
transaction prover, and a note transport, and it links to a block explorer. Your
wallet is separate software. Each service has its own terms and privacy policy.
The project does not control those services and is not responsible for their
acts or omissions.

## 12. Privacy

The [Privacy Policy](privacy.md) describes what the Interface stores in your
browser and what it sends to third parties. It is part of these Terms.

## 13. Changes, suspension, termination

The Interface can change, be suspended, or be discontinued at any time, in whole
or in part, without notice. These Terms can be revised; the current version is at
this address and carries the date of the revision. Continued use after a
revision is acceptance of it.

## 14. Miscellaneous

If a provision of these Terms is held unenforceable, it is severed and the
remaining provisions stay in force. A failure to enforce a provision is not a
waiver. These Terms, with the Privacy Policy, are the entire agreement between
you and the project concerning the Interface. Nothing in these Terms creates a
partnership, agency, joint venture, or employment relationship.

## 15. Contact

Email [hello@port0.sh](mailto:hello@port0.sh).
