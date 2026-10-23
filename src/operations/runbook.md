# Runbook

How to stand up the stack and deploy a pool. Four repositories take part.

| Repository | Role |
| --- | --- |
| `port0_contracts` | Pool component, registry component, and note scripts |
| `port0_sdk` | TypeScript SDK: contract artifacts, the registry account builder, and the pool operations |
| `port0_indexer` | Rust indexer: reads the registry and pools over node RPC, serves HTTP |
| `port0_app` | Static web app: browse pools, trade, provide liquidity, create pools |

Pin every dependency to the version the testnet runs. The manifests carry the
current pins.

## Part 1: one-time operator setup

### 1. Contracts

In the `port0_contracts` checkout:

```sh
cargo miden build --manifest-path contracts/port0/Cargo.toml --release
```

The SDK's artifact exporter builds the packages itself, so this step is only
needed to seed a fresh checkout.

### 2. SDK artifacts

In the `port0_sdk` checkout:

```sh
npm install
npm run generate   # exports the compiled packages into src/generated
npm run build
```

### 3. Pool code commitment

```sh
npm run pool:commitment
```

Prints the accepted pool code commitment, currently
`0xb3193d87f91e7a694d84de14c2bea7da627d7068d17a53b38a984a1739e0f0cb`. The value
covers the pool's full component set: the `port0` component, `CodeInspection`,
the network-account auth, and the fee-policy components. It changes whenever any
of those change, and the registry must be seeded with the value the deployed
pool produces.

### 4. Registry account

```sh
cp .env.example .env       # set PORT0_FEE_FAUCET_ID and PORT0_POOL_COMMITMENT
npm run registry:deploy
```

The tool is interactive. On first run it creates an operator wallet, prints its
bech32 address, and polls until the fee asset arrives. It consumes the incoming
note, then funds the registry with whatever the operator holds above the
transaction fee, capped at `PORT0_FUND`. Send at least 420 base units to
proceed. The tool claims the incoming note, keeps 119 for its own funding
transaction, and sends the rest up to `PORT0_FUND`; sending about 1238 funds the
registry with the default 1000 (claim fee plus the 119 reserve plus 1000). The
tool then builds
the registry with `createRegistryAccount`, funds it, and deploys it, printing
the registry id. No re-run is needed.

A stored registry is reused only when it accepts the configured pool code
commitment and admits both registry note kinds. An account that fails either
check is reported and a fresh registry is deployed instead.

Wait timeout: `PORT0_WAIT_SECS` (default 600). On timeout it prints the address
and exits. Keys and store: `~/.miden/stores/<PORT0_STORE>/`.

### 5. Indexer

In the `port0_indexer` checkout:

```sh
cp .env.example .env       # set PORT0_REGISTRY_ID to the registry id from step 4
cargo run --release
```

Serves `http://127.0.0.1:8080`, loopback by default for an API behind a reverse
proxy. `GET /status` reports the registry id, the last registry block, and the
known and fetched pool counts. Pools appear after the registry poll (default
60 s) and the pool poll (default 15 s).

The API answers cross-origin only for the origins in `INDEXER_ALLOWED_ORIGINS`.
The shipped `.env.example` lists the Vite dev ports, so `npm run dev` at
`http://localhost:5173` is admitted. A deployment that serves the app and the
API from one origin needs no entry.

### 6. App

In the `port0_app` checkout:

```sh
cp .env.example .env       # set VITE_REGISTRY_ID and VITE_INDEXER_URL=http://localhost:8080
npm run dev
```

`VITE_REGISTRY_ID` enables registration during pool creation.
`VITE_INDEXER_URL` is the pool source for browsing and the pool page. An empty
value disables both.

## Part 2: deploy a pool through the app

Prerequisite: the connected wallet holds USDCX. The wallet pays the pool funding
note and the sponsorship of the network notes it emits. Every note kind is
priced at the measured schedule (126 base units for the pool notes, 119 for the
registry notes at the current base fee), so the prepayment covers the actual
charge with a one-base-unit margin; the measured emit and swap-execution fees
are about 119 base units each.

1. Open `/create.html` and connect the wallet.
2. Choose the token pair. Either launch a fixed-supply token, which creates a
   faucet and funds it with `2 x 133 = 266` base units of USDCX, or enter two
   existing faucet ids.
3. Choose the LP fee tier: 5, 30, or 100 basis points, whichever the registry
   lists. The protocol's cut is a share of that fee, read from the registry and
   carved out of it, so the swapper pays the LP fee tier and nothing more.
4. Submit. The page runs three on-chain steps and reports each.

| Step | What happens | Who pays |
| --- | --- | --- |
| Create pool account | Built locally, not yet on chain. Fees, the P2ID root, and the registry pointer are initial storage; the LP token key is derived by the contract | Nothing |
| Deploy | The wallet sends 133 base units of USDCX to the pool; then the app consumes that note as the pool's first transaction | Wallet funds; the pool pays its first fee from the received funds |
| Register | Register note via the wallet, sponsored with the registry's register fee; the node's transaction builder consumes it against the registry, which verifies the pool code commitment, the registry pointer, the token pair, and the fee values by foreign procedure invocation | Wallet |

5. The page redirects to `/pool.html?id=<poolid>`. The pool appears on the home
   page once the indexer has polled the registry and fetched the pool. Until
   then the pool page shows a spinner and re-checks the indexer every 5 s, so
   the redirect lands on a page that fills itself in.

If a stage fails, the page keeps the flow state and shows Retry and Restart.
Retry resumes at the failed stage; it does not recreate the pool, and the deploy
stage reuses an existing funding note instead of sending a second one. Restart
clears the state and starts from the pool account.

## Part 3: deploy a pool programmatically

The same steps without the UI. The wallet-signed steps can be submitted by the
client directly when the account's key is in the client keystore.

```ts
import { MidenClient } from "@miden-sdk/miden-sdk";
import { XykClient } from "@port0.sh/sdk";

const client = await MidenClient.create({
  rpcUrl,
  feeFaucetId,
  proverUrl: "testnet",
  autoSync: true,
});
const xyk = XykClient.from(client);

// 1. Build the pool account locally. Fees, the P2ID root, and the registry
// pointer are initial storage; the LP token key is derived by the contract.
const account = await xyk.createPoolAccount({
  token0Key,
  token1Key,
  registryId,
  lpFeeBps: 30n,
  protocolFeeShareBps,
  p2idRoot,
  feeFaucetId,
  noteFees,
});
const poolId = account.id();

// 2. Fund it, then 3. deploy by consuming the funding note.
const { txId: fundTx } = await client.transactions.send({
  account: sender.toString(),
  to: poolId.toString(),
  token: feeFaucetId,
  amount: 133n,
  type: "public",
  waitForConfirmation: true,
});
await client.syncChain();
const consumable = await client.notes.listAvailable({ account: poolId.toString() });
await xyk.deployPoolAccount(poolId, consumable[0].id().toString(), {
  waitForConfirmation: true,
});

// 4. Register. The pool was configured when it was created: fees, the P2ID
// root, and the registry pointer are initial storage, and the LP token key is
// derived by the contract.
await xyk.registerPool(
  { registryId, feeFaucetId, registerFee },
  { sender, poolId, asset0: token0FaucetId, asset1: token1FaucetId },
  { submit: true, waitForConfirmation: true },
);
```

## Sweeping fees

Two permissionless sweeps move protocol fees to the fee recipient. The SDK runs
both:

```sh
npm run fees:collect -- registry --submit
npm run fees:collect -- pool <pool-id> --submit
```

Without `--submit` the command is a dry run. It reports what is claimable, where
it would go, and what the sweep costs the caller, and submits nothing.

Each sweep emits a collect note and a FEE_SPONSORSHIP note for it. The
sponsorship carries the collect note's prepaid fee, which is the measured
schedule price (126 base units for a pool collect, 119 for a registry collect at
the current base fee); the remainder stays in the
account and a later sweep collects it. When the swept key is the chain fee
asset, the contract leaves the transaction's own fee in the vault, so the
epilogue can pay it. The caller funds the sponsorship.

The caller is an account whose key is in the SDK's client store (`PORT0_STORE`,
default `port0-registry`), or the account named by `PORT0_OPERATOR`.
`PORT0_REGISTRY_ID` selects the registry, `PORT0_FEE_FAUCET_ID` is the chain
fee faucet, `MIDEN_RPC_URL` selects the node, and `PORT0_PROVER` selects the
prover (`testnet` by default). The caller must hold the chain fee asset; the
script prints the address and the amount when the balance is short.

The registry target sweeps the registry's whole balance of each asset the
registry holds. The pool target sweeps one pool's protocol pot plus any credit
above its reserves, in the pool's tokens and in any third asset the vault holds.

If the node's network transaction builder has not consumed the collect note
within `PORT0_PAYOUT_WAIT_SECS` (default 90), the script executes and submits
that same transaction itself. Funding and payout waits use `PORT0_WAIT_SECS`
(default 600).

## Failure conditions

| Symptom | Cause and fix |
| --- | --- |
| `PORT0_REGISTRY_ID is required` | The indexer has no registry id. Set it in `.env`. |
| `registry response is missing slot pool_registry::pool_registry::pools` | The indexer points at an account that is not the registry. Correct the id. |
| Pool absent from the home page | The indexer is not running, the registry id is wrong, or the register note has not been consumed by the node's builder yet. Check `GET /status`. |
| `Pool code commitment not accepted` at registration | The registry was seeded with a stale commitment. Re-run `npm run pool:commitment` and redeploy the registry, or register a pool built with the accepted component set. |
| Trading disabled on the pool page | The indexer could not read the pool's fee asset id or fee schedule. Check the pool's network-account slots. |
| `funding not received within Ns (balance X/Y)` | The operator address was not funded within the wait. Send it fee asset base units and re-run, or raise `PORT0_WAIT_SECS`. |
| `SummaryAnchorMismatchError` at register | The wallet captured its chain anchor at a block other than the request's bound block; a block landed between the two syncs. The page syncs the wallet immediately before the build to narrow the window. Retry rebuilds the request at a fresh tip. |
| `ERR_NETWORK_ACCOUNT_TRANSACTION_HAS_NO_EFFECT` | A network-account deploy with no effect. Deploy by consuming a funding note. |
| `procedure with root digest ... could not be found` | The client minor is behind the node. Bump every `@miden-sdk/*` and `miden-node-proto` pin to the node's version. |
