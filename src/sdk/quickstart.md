# Quick start

```ts
import { MidenClient } from "@miden-sdk/miden-sdk";
import { XykClient, deadlineFrom } from "@port0.sh/sdk";

const client = await MidenClient.create({
  rpcUrl: "https://rpc.testnet.miden.io/",
  feeFaucetId: "0x4cbdcaffe75f0a317482224dae6436", // chain fee faucet, required
  proverUrl: "testnet",
  autoSync: false,
});
await client.syncChain();

const xyk = XykClient.from(client);
const pool = xyk.pool({
  poolId,
  feeFaucetId,
  noteFees: { swap: 133n }, // fee schedule fixed at pool creation
});

const state = await pool.state();

const result = await pool.swap({
  sender,
  recipient,
  tokenIn: token0,
  amountIn: 1000n,
  slippageBps: 50n,
  deadline: deadlineFrom(latestBlockTimestamp, 3600n),
  // submit: true, waitForConfirmation: true,
});

// result.note, result.sponsorNote, result.request, result.quote,
// result.minAmountOut, result.tokenOut, result.fee, result.feeFaucetId
```

## Notes on the example

- `feeFaucetId` is required by `MidenClient.create` and must be the chain fee
  faucet. On the testnet it is USDCX.
- `proverUrl` selects the remote prover. Omitting it falls back to the local
  prover, which proves slowly.
- `syncChain` refreshes the local store, which is a cache of chain state.
- `Pool` fetches pool state internally, so each operation method is a single
  call.
- All amounts are `bigint` in the smallest unit of the asset. All account ids
  are the web-sdk `AccountId` type.

## Amounts and words

```ts
type Word4 = readonly [bigint, bigint, bigint, bigint];
type SerialNumber = Word4;
```

`Word4` is a four-limb value: an asset key, a registry id word, or a serial.
`SerialNumber` is the same shape.
