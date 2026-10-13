# Errors

Protocol and integration errors seen in operation, with the cause and the fix.

| Symptom | Cause | Fix |
| --- | --- | --- |
| `null pointer passed to rust` | A main-thread WASM object passed to the worker client | Pass hex strings into every client method |
| `expected instance of X` or `e` | Two WASM copies in the bundle, or a cross-instance object | Force one copy with Vite `resolve.dedupe`; build all objects from one module |
| `procedure with root digest ... could not be found` | The client minor is behind the node | Bump every `@miden-sdk/*` and `miden-node-proto` pin to the node's version |
| `no account header record found for given ID` | The account is not in the local store, or the handle is stale | Import the account; pass strings |
| `could not interpret input as a bech32-encoded account id ... invalid checksum` | A bare hex id failed the hex test and was parsed as bech32 | Test with `/^(?:0x)?[0-9a-f]+$/i`, or prefix `0x` |
| Empty-vault assertion on a faucet mint or deploy | A fresh account pays its own fee | Fund with a note and consume it as the first transaction |
| `ERR_NETWORK_ACCOUNT_TRANSACTION_HAS_NO_EFFECT` | An empty scriptless deploy of a network account | Deploy by consuming a funding note |
| `advice stack read failed` on a multisig | A two-word fee-conversion preimage where three words are read | Build the three-word `MultisigAuthArgs` |
| `account's ... component reuses the fee conversion salt ...` | No salt declared for a multisig | Declare a fresh salt, or the full `MultisigAuthArgs` |
| `storage root not found ... slot ... block` | Declaring specific storage slots on a public foreign account | Use empty storage requirements; a public target resolves lazily |
| `SummaryAnchorMismatchError ...` | The wallet captures a chain anchor at its own sync height while a multisig summary binds the request's bound block | Sync the wallet immediately before the build. Retry rebuilds the request at a fresh tip |
| `private account ... cannot be retrieved` | Importing a private account | Private accounts are not importable |
| `invalid amount: 250,000` | An amount parser rejects grouping commas while a formatter emits them | Strip commas in the parser |
| `Cannot access 'x' before initialization` | A render helper runs before a `const` or `let` it reads is initialized | Declare the variable above the first call |
| `Cannot read properties of undefined (reading 'includes')` | Module code runs before a `const` declared later | Move the bootstrap call to the end of the module |

## Rule

A protocol rejection names a violated invariant. Resubmitting until the error
stops hides the cause and turns a deterministic defect into an intermittent one.
Change the code so the invariant holds on the first attempt.
