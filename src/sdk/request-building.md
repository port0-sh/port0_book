# Request building

The SDK turns parameters into notes and assembles the transaction request a
wallet executes. This chapter describes the layers below the operations.

## Note builders

Each builder returns a web-sdk `Note`. The pool feature builders produce a public
network note with a `NetworkAccountTarget` attachment to the target account.

```ts
buildMintNote(input: MintNoteInput): Note
buildBurnNote(input: BurnNoteInput): Note
buildSwapNote(input: SwapNoteInput): Note
buildCollectNote(input: CollectNoteInput): Note
buildRegisterNote(input: RegisterNoteInput): Note
buildRegistryCollectNote(input: RegistryCollectNoteInput): Note
buildRegistryConfigNote(input: RegistryConfigNoteInput): Note
buildLaunchNote(input: LaunchNoteInput): Note
buildFeeSponsorshipNote(input: FeeSponsorshipNoteInput): Note

p2idRoot(): Word4
noteScript(kind: NoteKind): NoteScript
POOL_NOTE_KINDS: readonly PoolNoteKind[]  // ["mint","burn","swap","collect"]
NOTE_KINDS: readonly NoteKind[]           // POOL_NOTE_KINDS plus "register", "registry-collect", "registry-config", "launch"
```

Common input fields are `sender`, `poolId`, `recipient` where applicable,
`deadline`, and the `min_*` slippage bounds. The `serial` defaults to
`randomSerial()`, and `tag` defaults to `accountTargetTag(recipient)`.

`buildRegisterNote` takes `sender`, `registryId`, `poolId`, `asset0`, and
`asset1`. The note targets the registry and carries the 8-felt register layout
with no assets.

`buildCollectNote` takes `sender`, `poolId`, `assetKeys`, and an optional
`serial`. The note targets the pool and carries the pool id, the serial, and one
asset key per swept asset, so `6 + 4n` felts and no assets.

`buildRegistryCollectNote` takes `sender`, `registryId`, `assetKeys`, and an
optional `serial`. The note targets the registry and carries the registry id,
the serial, and one asset key per swept asset, so `6 + 4n` felts and no assets.

`buildRegistryConfigNote` takes `sender`, `registryId`, and `registerFee`. The
note targets the registry, carries the registry id, the new fee, and the
register note's script root, and is accepted only when `sender` is the registry
admin. The root comes from the compiled register note rather than a constant,
because the root moves when the registry's interface changes.

`buildFeeSponsorshipNote` takes `sender`, `target`, `featureNote`,
`feeFaucetId`, `feeAmount`, and optional `reclaimer` (defaults to `sender`) and
`reclaimHeight` (defaults to `0`, disabled). The note carries exactly one
`FungibleAsset(feeFaucetId, feeAmount)` and no attachment.

`noteScript(kind)` deserialises the compiled package from
`src/generated/contracts.ts` once and caches it.

## Note storage layouts

Each function returns `bigint[]` in the exact order the note script asserts.

| Function | Felts | Layout |
| --- | --- | --- |
| `mintNoteStorage` | 11 | pool, recipient, serial, tag, deadline, `minLpOut` |
| `burnNoteStorage` | 12 | pool, recipient, serial, tag, deadline, `minAmount0`, `minAmount1` |
| `swapNoteStorage` | 11 | pool, recipient, serial, tag, deadline, `minAmountOut` |
| `collectNoteStorage` | 6 + 4n | pool, serial, one asset key (4) per swept asset |
| `registerNoteStorage` | 8 | registry, pool, asset0, asset1 |
| `registryCollectNoteStorage` | 6 + 4n | registry, serial, one asset key (4) per swept asset |
| `feeSponsorshipStorage` | 7 | feature note id (4), reclaimer `[suffix, prefix]`, reclaim height |

Account ids inside layouts are `[prefix, suffix]`. The reclaimer in
`feeSponsorshipStorage` is the exception: it is `[suffix, prefix]`, matching
`FeeSponsorshipNoteStorage`. A collect note carries at most four asset keys; a
longer list is rejected by the note script.

## Encoders

```ts
accountIdFelts(id): [bigint, bigint]          // [prefix, suffix]
fungibleAssetIdWord(faucetId): Word4          // [0, 0, suffix | 0x11, prefix]
accountTargetTag(id): bigint                  // top 14 prefix bits, low bits zeroed
randomSerial(): SerialNumber
randomSeed(): Uint8Array                      // 32 bytes
isWord4(value): value is Word4
ACCOUNT_TARGET_TAG_LEN                        // 14
```

`accountTargetTag` is computed in `bigint`. JavaScript number bitwise operators
truncate to int32 and produce a negative tag whenever bit 31 of the prefix is
set.

## Combined request

```ts
ownOutputNotesRequest(
  client: MidenClient,
  notes: Note[],
  targetPoolId: AccountId,
): Promise<TransactionRequest>
```

The function builds one `TransactionRequest` with `notes` as own output notes,
plus the machinery a wallet-executed multisig request needs:

- A three-word `MultisigAuthArgs` preimage,
  `[boundBlock, 0, 0, 0] || SALT || CONVERSION_INFO` (12 felts), committed with
  `Poseidon2.hashElements` and declared with `withAuthArg`, with the preimage in
  the advice map. `SALT` is fresh per request. `CONVERSION_INFO` is
  `[feeFaucetId.suffix, feeFaucetId.prefix, 1, 1]`, read from
  `client.feeFaucetId()`. The bound block is `client.getSyncHeight()`.
- The target pool as a foreign account with empty storage requirements, so the
  kernel prices the emitted network note through `estimate_note_fee`.

Notes are pushed rather than constructor-consumed so the caller keeps valid
`Note` references.

### Local signer

```ts
outputNotesRequest(
  client: MidenClient,
  notes: Note[],
  targetAccountId: AccountId,
): Promise<TransactionRequest>
```

The twin of `ownOutputNotesRequest`, for an account whose key the client holds.
The wallet variant declares the multisig `MultisigAuthArgs` preimage a wallet
reads. A local account signs instead, and the client attaches the signature and
the conversion info it fetched itself. Declaring the multisig preimage for a
local sender puts two conversion infos in play, and the kernel rejects the
transaction. This variant declares no auth args and no block numbers.

The target account is still declared as a foreign account, so the kernel prices
the emitted network note through `estimate_note_fee`.

### Note execution hint

Every network note the SDK builds carries `NoteExecutionHint.always()` on its
`NetworkAccountTarget` attachment. A target built without the hint emits
`NoteExecutionHint::None`, which tells the node not to schedule the note, and
the note is never consumed.

## Pool and registry creation

```ts
createPoolAccount(client, params): Promise<Account>
buildPoolAccount(client, params): Promise<Account>
poolCodeCommitment(client, params): Promise<string>
poolAuthRoots(client, params): Promise<PoolAuthRoots>
deployPoolAccount(client, poolId, fundingNoteId, options?): Promise<TransactionSubmitResult>
createFeeFaucet(client, params): Promise<Account>
lpFaucetComponent(client, params): Promise<AccountComponent>
createRegistryAccount(client, params): Promise<Account>
deployRegistryAccount(client, registryId, fundingNoteId, options?): Promise<TransactionSubmitResult>
readRegistryRegisterFee(getAccount, registryId): Promise<bigint>
```

`CreatePoolAccountParams` is `{ token0Key, token1Key, token0Symbol, token1Symbol,
registryId, lpFeeBps, protocolFeeShareBps, p2idRoot?, feeFaucetId, noteFees?,
seed? }`. `createPoolAccount` builds the pool component from the compiled
package and the eleven init slots, installs the standard basic fungible faucet
component so the LP token carries readable metadata (see [account
components](../contracts/pool.md#account-components)), installs the
standard `CodeInspection` component, installs the network auth with the fee
schedule, and inserts the account into the client's local store. It does not
deploy. The fee schedule defaults every note kind to `NOTE_FEES`.

`poolAuthRoots` returns the auth roots a registry must be created with: the note
allowlist root, the transaction-script allowlist root, and the fee schedule
root, plus the fee asset and fee policy roots. The registry compares them
against every pool it registers.

`poolCodeCommitment` returns the account code commitment as lowercase hex,
which is the value the registry's `accepted_code_commitments` map must hold. It
is computed through the same path as `createPoolAccount`, so it cannot drift
from a deployed pool.

`deployPoolAccount` consumes the funding note as the pool's first transaction.
The network auth rejects a transaction with no effect, so a scriptless
deploy fails. The pool id is passed to `transactions.consume` as a hex string,
not as an `AccountId`, because the client re-parses account references
worker-side.

`buildLaunchNote` takes `sender`, `faucetId`, `recipient`, and optional
`serial` and `tag`. The note targets a network faucet and carries the 9-felt
launch layout. The faucet accepts it only from the owner and only before the
supply is minted.

`CreateRegistryAccountParams` is `{ acceptedPoolCodeCommitment, feeFaucetId,
registerFee, protocolFeeTo, protocolFeeShareBps, allowedLpFeeBps, p2idRoot,
admin, authRoots, seed? }`. `createRegistryAccount` seeds
`accepted_code_commitments` and `allowed_lp_fee_bps`, stores the expected pool
auth roots and the admin, and prices the three registry note kinds in the
network auth from `NOTE_FEES`: the register note at `registerFee`, which
defaults to `NOTE_FEES.register` when zero, registry-collect at
`NOTE_FEES["registry-collect"]`, and registry-config at zero, because the
registry pays that fee from the register fees it holds. `deployRegistryAccount`
consumes a funding note as the first transaction.

`readRegistryRegisterFee` reads the live register fee from the registry's fee
schedule, which is authoritative after the admin changes it.
`readRegistryAdmin` reads the account allowed to change that fee.

`createFeeFaucet` creates a public fungible faucet for an application that needs
ongoing minting. A fixed-supply token that mints once is a network faucet:

```ts
buildNetworkFaucet(client, params: CreateNetworkFaucetParams): Promise<Account>
createNetworkFaucet(client, params: CreateNetworkFaucetParams): Promise<Account>
deployNetworkFaucet(client, faucetId, fundingNoteId, options?): Promise<TransactionSubmitResult>
LAUNCH_FEE: bigint

standardFaucetComponent(client, params): Promise<AccountComponent>
fungibleFaucetSlots(params): PoolInitSlotDefinition[]
```

`CreateNetworkFaucetParams` is `{ name, symbol, decimals, maxSupply, owner,
feeFaucetId, seed? }`. The account carries the `network-faucet` component, the
standard basic fungible faucet component, and the network auth. `deployNetworkFaucet`
consumes a funding note as the account's first transaction; the supply is minted
later by the owner's launch note.

A pool's `feeFaucetId` must be the chain fee faucet, or the node never consumes
the pool's notes. The SDK's faucet helpers do not change that: the chain fee
faucet comes from `client.feeFaucetId()`.

## Discovery

```ts
isXykPool(account: Account): boolean
xykNoteScriptRoots(): Record<PoolNoteKind, string>
class PoolRegistry { register(poolId); get(canonicalId); list() }
```

`isXykPool` returns true when the account is a network account whose
note-script allowlist contains all four pool note roots. The node RPC has no
account-listing-by-code-root endpoint, so chain-wide discovery belongs to the
indexer.
