# Receiving-device receipt schema

Last verified: 2026-07-31

The receipt schema is the last additive artifact needed before a real second computer can prove it reconstructed this machine's context. It defines one value-safe JSON document that a receiving computer emits after it finishes onboarding, so the claim "another computer can pick this up" becomes checkable rather than asserted.

## Where it lives

- Schema: [`handoffs/RECEIVING-DEVICE-RECEIPT.schema.json`](https://github.com/douglaspmcgowan/general-ai/blob/master/handoffs/RECEIVING-DEVICE-RECEIPT.schema.json)
- Raw: [raw.githubusercontent.com copy](https://raw.githubusercontent.com/douglaspmcgowan/general-ai/master/handoffs/RECEIVING-DEVICE-RECEIPT.schema.json)
- Repository: `douglaspmcgowan/general-ai`, merged in pull request 10 at `84f1cf6`.
- Entrypoint that links it: [cross-device access index](https://github.com/douglaspmcgowan/general-ai/blob/master/CROSS-DEVICE-ACCESS.md)

## What the receipt records

Twelve required sections, all mandatory:

1. `runMetadata` — run identifier, timestamps, machine alias, operating system family/edition/version/build/architecture.
2. `harness` — repository, acquisition mode (`git-clone` or `authenticated-zip`), branch, commit, onboarding entry, manifest hash and verification result, install path and status, setup integrity stamp.
3. `obsidian` — receiving-side backup, restore status, bundle version and hash, installed plugin IDs with versions and enabled/verified state, and a boolean confirming protected paths stayed excluded.
4. `projectData` — the project data root and sync root, whether the environment variable persisted, and whether both roots exist and are writable.
5. `executables` — each required program with discovery result, resolved path, version, and status.
6. `github` — authentication availability, identity verification as a boolean, `agent-project` topic discovery, and a per-repository clone/pull/attention result including working-tree cleanliness and Actions status.
7. `projectVerification` — the verifier each repository ran and its result.
8. `dataAdapters` — declared adapter per repository (`none`, `regenerable`, `dvc`, `sqlite`, `other-declared`), the operation performed, and artifact checksums.
9. `bitwarden` — value-free machine-account evidence only.
10. `accessSurfaces` — exactly four surfaces, each with reachability, content verification, and a phone-safe flag.
11. `attentionInventory` — coded, severity-ranked, owner-assigned open items.
12. `finalAssessment` — `PASS`, `ATTENTION`, or `FAIL`, with a timestamp and a completeness boolean.

## Safety properties the schema enforces

- Every object sets `additionalProperties: false`, so a stray credential field is structurally rejected rather than merely discouraged.
- Bitwarden evidence is boolean and value-free, and the import variable name is pinned to `BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN` by a `const`. No token, account identifier, or password can appear.
- The receipt names exactly four unique access surfaces: `general-ai`, `harness`, `agent-brain`, and `docket`. A missing or duplicated surface fails validation.
- `harness.commit` must be a full 40-character SHA, so the final assessment binds to one exact harness commit rather than an ambiguous abbreviation.
- SQLite snapshot retention is capped at five distinct snapshots and must preserve the newest verified snapshot. `snapshotRetention` is forbidden on any adapter other than `sqlite`.
- Data-adapter evidence carries checksums and opaque artifact identifiers. Protected data contents are excluded by construction.

## Verification performed

- The schema compiles as JSON Schema 2020-12.
- One positive fixture validates.
- Twelve negative fixtures are rejected: a credential field added to the Bitwarden section, a credential field added to the harness section, retention above five snapshots, a SQLite adapter missing its retention block, a retention block on a non-SQLite adapter, `preserveNewestVerified` set false, a duplicated access surface, a missing fourth access surface, an abbreviated harness commit, an unknown top-level section, a wrong onboarding entry, and a wrong Bitwarden import variable.
- Gitleaks 8.30.1 over the full worktree reported no leaks, `git diff --check` was clean, every JSON file parsed, and the YAML inventory loaded.

## What still has to happen

The schema describes the proof. It does not supply it. One real receiving computer still has to run the merged onboarding flow and emit a conforming receipt. Three harness-owned repairs gate that run, and they belong to the active harness owner: the installed-verifier allowance for the two harness-owned mutable runtime files, capture of the approved Obsidian bundle including the pinned community-plugin package, and moving prerequisite discovery ahead of the Obsidian and Project Data stages.
