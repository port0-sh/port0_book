# Changelog

All notable changes to this documentation are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.4.0] - 2026-10-31

### Added

- The activity endpoint's contract: transactions only, the price from the row's
  amounts, `unrecorded`.
- The events endpoint's contract: the per-transaction log, the exactness flag,
  and the `deploy` kind.
- The `/legacy` route and the recovery's storage statements.

### Changed

- The contracts pages follow the 0.4 behaviour: the refund path, the lifecycle
  check, the 126 schedule, the LP supply write.
- The polling and storage pages describe the backfill and the startup recovery.
- The network reference and the runbook follow the node and fee facts.

### Fixed

- The activity section's observation rows and reserve fields, and the "backfill
  not implemented" statements.

## [0.3.4] - 2026-10-30

Initial release.

### Added

- Getting started: opening a pool.
- Concepts: the constant-product AMM, accounts and notes, and the glossary.
- Contracts: overview, pool, registry, network faucet, notes, fees, limits and
  failure conditions, and the security model.
- SDK: install, quick start, operations, request building, and errors.
- Indexer: overview, configuration, storage and retention, polling, capacity,
  and the HTTP API.
- App: overview, the closed-alpha risk notice, configuration, wallets, and
  token minting.
- Legal: terms of service and privacy policy.
- Operations: the runbook.
- Reference: network, errors, repositories, and contact.
