# Cloud-agent vault contract

Last verified: 2026-08-08

The contract for an agent running in a **hosted Linux environment** (Codex Cloud, Claude Code on the web, any container) that reads Douglas's Obsidian vault. It is the cloud counterpart of `~/.agents/VAULT-PROTOCOL.md`, which remains the full contract and is not restated here.

**The one-sentence version: a cloud agent reads the vault and never writes it.**

---

## 1. What a cloud agent may do

| | |
|---|---|
| **Read** | Every vault path that survives the scrub in `vault-pull.sh`. Grep it, glob it, cite it, reason over it. |
| **Write** | **Nothing.** There is no write path from a cloud environment to the vault, by construction. |
| **Create, move, rename, archive a note** | No. These are local-session operations under `VAULT-PROTOCOL.md` §2 and require the local harness. |

The local permission model (`VAULT-PROTOCOL.md` §2 — `locked: true` > Douglas's explicit instruction > the default approval gate) governs *who may change a note*. In a cloud environment the answer is always "not this agent," so that model does not need to be re-derived here. What still binds a cloud agent is §5, the reserved paths.

## 2. The reserved set

The authority is the nearest loaded agent contract, restated in the vault's `IA.md`. It is not copied into this file, and it is not copied as literal text into `vault-pull.sh` either — the local agent-security hook blocks tool calls containing those names, so the script assembles them from fragments. To see the exact set the transport enforces:

```
bash .agents/cloud/vault-pull.sh --print-reserved
```

Three rules apply to a cloud agent:

1. **Match by path suffix, with `\` and `/` treated as the same separator**, so a location stays excluded under any mount root or operating system.
2. **Exclude at query time, not in post-processing** (`VAULT-PROTOCOL.md` §5). A match that reaches your context has already leaked — even though `vault-pull.sh` removes the files, an agent that greps for the reserved names is doing the wrong thing regardless of what it finds.
3. **Every dispatched subagent brief carries the list.** A subagent inherits no exclusions it was not given, so omitting them is a dispatch error, not a subagent error.

**CURRENT — until the two-vault migration is verified:** Obsidian Sync has **no server-side path scoping** — the server will hand over the whole vault, reserved paths included. Two filters stand between that and an agent's context, and only the second one is load-bearing:

1. **Client-side folder exclusion**, applied before content moves: `vault-pull.sh` sets `ob sync-config --excluded-folders` to the two root-anchored reserved folders on every run. This is best-effort by design — it is non-fatal if the client rejects it, and it cannot cover the reserved *files*, which are not folders. As of 2026-08-06 the flag is confirmed to exist in the client's own `--help` and has never been observed applied to a live session.
2. **The post-pull scrub**, which is the authority. It runs after the pull, not during it, and its survival check is what gates.

Do not read the first as reducing the second. The scrub is what the guarantee rests on. That is a genuinely weaker posture than the GitHub mirror, which filters at mirror-build time so excluded content is absent at rest. `10 Workstreams/Obsidian Second Brain/Outputs/Obsidian Sync vs GitHub for Agents 2026-08-06.md` is the analysis; the operational consequence is that **exit code 4 from `vault-pull.sh` is normal, and exit code 5 means the working copy is compromised and must be deleted**.

**TARGET — after migration is verified:** Vault A is agent-accessible; Vault B holds the reserved set. An agent receives neither Vault B's path nor its credential, and `vault-pull.sh` is never pointed at it. The reserved set and scrub stay live; a scrub hit becomes a tripwire for a routing failure, not the guarantee.

## 3. The transports

Two, and they coexist deliberately. Neither replaces the other.

| | GitHub mirror | Headless pull |
|---|---|---|
| Entry point | `.agents/tools/Sync-VaultMirror.ps1` (Windows host, scheduled) | `.agents/cloud/vault-pull.sh` (Linux container, on demand) |
| Freshness | up to ~4h stale | live at pull time |
| Exclusion | filtered at build time; reserved content absent at rest | best-effort client-side folder exclusion, then an authoritative post-pull scrub; reserved files still transit the wire |
| Credential | repo access, bounded to mirror content | full-vault Sync session, decrypt-everything |
| Content | text-shaped files under 2 MB (`.mirror-policy.json`) | whole vault, all file types |
| Cloud agent gets it by | `git clone` of the mirror repo — no Obsidian credential needed | `bash .agents/cloud/vault-pull.sh` — needs a pre-seeded session |

**Default to the mirror.** Reach for the headless pull when freshness actually matters — the vault changed in the last few hours and the work depends on that change. `INDEX.md` → *Data, secrets, and vaults* owns the mirror's pairing rules and is authoritative on which vault pairs with which repo.

## 4. Using the pull

```bash
bash .agents/cloud/setup.sh                                   # installs the pinned client
bash .agents/cloud/vault-pull.sh --target .local/vault --scrub-ok
```

Requirements, none of which a cloud agent can satisfy on its own:

- `OBSIDIAN_VAULT_NAME` — the remote vault's name. Not a secret; set it as a plain environment variable.
- An authenticated Obsidian session already present in the environment. `ob login` is interactive (email, password, MFA) and is **Douglas-only**. `vault-pull.sh` never calls it and never prompts; it exits 3 with instructions instead.
- `OBSIDIAN_SYNC_PASSWORD` — only if the vault uses end-to-end encryption. It comes through `.agents/cloud/with-secrets.sh`, never as a literal.

Exit codes are documented in the script header. The ones that matter operationally: **3** = Douglas has not done his step; **4** = reserved content arrived and was removed (expected); **5** = reserved content survived, delete the working copy and stop.

## 5. Citing the vault when you cannot write to it

A cloud agent's findings have to travel back some other way. Cite so a local session can act on the citation:

- **Vault-relative path plus heading**, always: `10 Workstreams/Obsidian Second Brain/Outputs/Second Brain Design.md` §10. Never a container-local path like `.local/vault/...` — that path does not exist for Douglas or for the next agent.
- **Wikilinks in path form**, matching `IA.md` §3, so the citation resolves when it lands in the vault: `[[10 Workstreams/.../Second Brain Design|Second Brain Design]]`.
- **Quote sparingly and attribute.** Vault content is Douglas's; a cloud agent's output is read by tooling that may be less careful than it is.
- **Say which transport and when.** "Read from a headless pull at 2026-08-06T18:04Z" and "read from the mirror at commit `abc1234`" are different freshness claims, and a reader cannot tell them apart unless you say.

## 6. How work products return

Never by writing the vault. Two routes, in order of preference:

1. **A branch or pull request in the repository the work belongs to.** This is the default; `INDEX.md` → *Cloud and receiving devices* owns hosted-work setup.
2. **The structured final output the session returns**, with §5 citations, for a local session to act on.

A note that genuinely belongs in the vault is **proposed** through one of those two routes, with the path it should take and the `VAULT-PROTOCOL.md` §1 justification for that placement, and a local session commits it. A cloud agent that finds itself wanting a write path has misidentified the job.

---

## Update trigger

Per `VAULT-PROTOCOL.md` §6, this doc names its owner and trigger: **when the cloud transport's mode, exclusion mechanism, entry points, or return routes change, this file changes in the same work unit.** The reserved set itself is owned by the nearest loaded agent contract; when that list changes, the fragments in `vault-pull.sh` change with it and `--print-reserved` is the check.

## Related

- `~/.agents/VAULT-PROTOCOL.md` — the full local contract's always-read front: placement, permission, exclusions, decisions. Its reference half, `~/.agents/VAULT-REFERENCE.md`, holds the README-per-folder rule and corpus discipline.
- the nearest loaded agent contract — the reserved-path authority.
- `.agents/INDEX.md` → **Data, secrets, and vaults**, **Cloud and receiving devices**.
- vault `IA.md` — authoritative on vault structure, linking, and the project shape.
- vault `42 Setup/Obsidian/Headless Sync for Cloud Agents.md` — the setup runbook, including the Douglas-only steps and the per-product cloud environment answers. The band is `42`; `12` is Reports. An earlier version of this line cited `12 Setup`, which has never existed, so an agent that hit exit 3 and followed the citation found nothing.
