#!/usr/bin/env bash
# landed-sweep.sh — does the app-repair renovation actually exist on each app's default branch?
#
# READ-ONLY over every app repository. It runs no fetch, no checkout, no merge, no push.
# Origin state is read with `git ls-remote` (which writes nothing) and with the
# remote-tracking refs already present locally; pull-request state with `gh pr list`.
#
# Unit set: every app unit with an audit record in app-atlas/data/audit/ (38 files).
# Repair branch: the convention every audit record uses, agent/<app>-repair. Recorded
# per app so a rename shows up as MISSING rather than as LANDED.
#
# Two questions per unit, kept apart on purpose:
#   1. is the repair branch an ancestor of the default branch (i.e. merged)?
#   2. is the floor artifact present on the default branch at all?
# A unit can fail (2) while passing (1); that is the worse finding.
#
# Artifact probe: `:focus-visible` occurrence count in tracked files, counted on the
# DEFAULT branch and on the REPAIR branch. It is the app-repair program's own floor
# metric and it is uniform across all 38 units, which the audit records are not — their
# schemas differ record to record. `git grep -c` prints paths and counts only, never file
# contents, so it cannot leak the credential one app is known to carry in a tracked file.
#
# CRLF: any TSV read here is passed through `tr -d '\r'` first. tools/m4-roster-roots.tsv
# on this branch is CRLF and an unguarded `while IFS=$'\t' read` over it appends a
# carriage return to every path and reports every row MISSING in under a second.

set -uo pipefail

AUDIT_DIR="${AUDIT_DIR:-C:/Users/dougl/Projects/app-atlas/data/audit}"
PROJECTS="${PROJECTS:-C:/Users/dougl/Projects}"
DATE="${SWEEP_DATE:-$(date +%Y-%m-%d)}"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${OUT:-$SELF_DIR/landed-sweep.$DATE.tsv}"
USE_GH="${USE_GH:-1}"
TMP="${TMPDIR:-/tmp}/landed-sweep.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

[ -d "$AUDIT_DIR" ] || { echo "landed-sweep: audit dir not found: $AUDIT_DIR" >&2; exit 2; }

default_branch() {
  local r="$1" b c
  b="$(git -C "$r" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  if [ -n "$b" ]; then printf '%s\torigin-HEAD\n' "${b#origin/}"; return; fi
  for c in main master; do
    git -C "$r" rev-parse --verify --quiet "refs/remotes/origin/$c" >/dev/null \
      && { printf '%s\torigin-ref\n' "$c"; return; }
  done
  for c in main master; do
    git -C "$r" rev-parse --verify --quiet "refs/heads/$c" >/dev/null \
      && { printf '%s\tlocal-ref\n' "$c"; return; }
  done
  b="$(git -C "$r" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  printf '%s\thead-fallback\n' "${b:-UNKNOWN}"
}

# origin-tracking ref preferred over the local head, so "landed" means landed where
# Douglas looks, not merely in this checkout
ref_for() {
  local r="$1" b="$2"
  if git -C "$r" rev-parse --verify --quiet "refs/remotes/origin/$b" >/dev/null; then
    echo "refs/remotes/origin/$b"
  elif git -C "$r" rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then
    echo "refs/heads/$b"
  fi
}

fv_count() {  # :focus-visible occurrences at a ref; paths+counts only, no file contents
  local r="$1" ref="$2" n
  [ -z "$ref" ] && { echo NA; return; }
  n="$(git -C "$r" grep -c -F -e ':focus-visible' "$ref" 2>/dev/null \
        | awk -F: '{s+=$NF} END {print s+0}')"
  echo "${n:-0}"
}
readme_on_ref() {
  local r="$1" ref="$2"
  [ -z "$ref" ] && { echo NA; return; }
  git -C "$r" ls-tree -r --name-only "$ref" 2>/dev/null | tr -d '\r' \
    | grep -qiE '^readme(\.md|\.txt)?$' && echo yes || echo no
}
slug_of() { printf '%s' "$1" | sed -E 's|^.*github\.com[:/]||; s|\.git$||'; }

# Two of the 38 units are not the repository at Projects/<app>: the app is a NESTED
# repository inside it (study-system -> berkeley-prelim-study, text-to-spaceship ->
# text-to-satellite). When the outer repo has no agent/<app>-repair branch, look one or
# two levels down for a repo that does, and measure that one instead.
resolve_repo() {
  local app="$1" outer="$2" rb="agent/$1-repair" g d
  if git -C "$outer" rev-parse --verify --quiet "refs/heads/$rb" >/dev/null \
     || git -C "$outer" rev-parse --verify --quiet "refs/remotes/origin/$rb" >/dev/null; then
    printf '%s\touter\n' "$outer"; return
  fi
  while read -r g; do
    d="$(dirname "$g")"
    case "$d" in "$outer") continue ;; esac
    if git -C "$d" rev-parse --verify --quiet "refs/heads/$rb" >/dev/null \
       || git -C "$d" rev-parse --verify --quiet "refs/remotes/origin/$rb" >/dev/null; then
      printf '%s\tnested\n' "$d"; return
    fi
  done < <(find "$outer" -maxdepth 3 -name .git -not -path '*/node_modules/*' 2>/dev/null | sort)
  printf '%s\touter\n' "$outer"
}

printf 'app\trepo_path\trepo_kind\tremote\tdefault_branch\tresolved_by\tchecked_out\trepair_branch\trepair_exists\trepair_merged\tahead_of_default\topen_pr\tpr_base\tworktree_on_repair\tfv_default\tfv_repair\treadme_default\tother_unlanded_agent_branches\tverdict\n' > "$OUT"

t=0; landed=0; upr=0; unopr=0; norem=0; absent=0; missing=0

for f in "$AUDIT_DIR"/*.json; do
  app="$(basename "$f" .json)"; t=$((t+1))
  repo="$PROJECTS/$app"
  rb="agent/$app-repair"

  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    printf '%s\t%s\tnone\tNO-GIT-REPO\t-\t-\t-\t%s\tno\t-\t-\t-\t-\t-\tNA\tNA\tNA\t-\tNO-REPO\n' "$app" "$repo" "$rb" >> "$OUT"
    continue
  fi
  IFS=$'\t' read -r repo repokind <<<"$(resolve_repo "$app" "$repo")"

  remote="$(git -C "$repo" remote get-url origin 2>/dev/null)"; [ -z "$remote" ] && remote=NONE
  case "$remote" in *github.com*) gh_ok=1 ;; *) gh_ok=0 ;; esac

  IFS=$'\t' read -r defb defby <<<"$(default_branch "$repo")"
  dref="$(ref_for "$repo" "$defb")"
  checked="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)"; [ -z "$checked" ] && checked=DETACHED

  # does the repair branch exist anywhere: local head, origin-tracking, or live on origin
  rref="$(ref_for "$repo" "$rb")"
  on_origin=no
  if [ "$remote" != NONE ]; then
    git -C "$repo" ls-remote --heads origin "refs/heads/$rb" 2>/dev/null | grep -q . && on_origin=yes
  fi
  if [ -n "$rref" ]; then rexists=yes; elif [ "$on_origin" = yes ]; then rexists=origin-only-unfetched; else rexists=no; fi

  merged=-; ahead=-; fvr=NA
  if [ -n "$rref" ] && [ -n "$dref" ]; then
    if git -C "$repo" merge-base --is-ancestor "$rref" "$dref" 2>/dev/null; then
      merged=yes; ahead=0
    else
      merged=no
      ahead="$(git -C "$repo" rev-list --count "$dref..$rref" 2>/dev/null)"; [ -z "$ahead" ] && ahead='?'
    fi
    fvr="$(fv_count "$repo" "$rref")"
  elif [ "$rexists" = origin-only-unfetched ]; then
    merged=unknown-unfetched
  fi

  pr=none; prbase=-
  if [ "$USE_GH" = 1 ] && [ "$gh_ok" = 1 ] && [ "$rexists" != no ]; then
    read -r pr prbase <<<"$(gh pr list --repo "$(slug_of "$remote")" --head "$rb" --state open \
        --json number,baseRefName --jq 'if length==0 then "none -" else (map("#\(.number)")|join(",")) + " " + (.[0].baseRefName) end' 2>/dev/null)"
    [ -z "${pr:-}" ] && { pr=gh-failed; prbase=-; }
  elif [ "$gh_ok" != 1 ]; then
    pr=no-github-remote
  fi

  wt="$(git -C "$repo" worktree list --porcelain 2>/dev/null | tr -d '\r' \
        | awk -v b="refs/heads/$rb" '/^worktree /{p=$2} /^branch /{if($2==b) print p}' | head -1)"
  [ -z "$wt" ] && wt=no

  fvd="$(fv_count "$repo" "$dref")"
  rme="$(readme_on_ref "$repo" "$dref")"

  # context only: other agent/* or cloud/* branches carrying unlanded commits
  other=0
  while read -r b; do
    [ -z "$b" ] && continue; [ "$b" = "$rb" ] && continue
    r2="$(ref_for "$repo" "$b")"; [ -z "$r2" ] && continue
    [ -z "$dref" ] && continue
    git -C "$repo" merge-base --is-ancestor "$r2" "$dref" 2>/dev/null || other=$((other+1))
  done < <({ git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads/agent refs/heads/cloud 2>/dev/null
             git -C "$repo" for-each-ref --format='%(refname:short)' refs/remotes/origin/agent refs/remotes/origin/cloud 2>/dev/null | sed 's|^origin/||'
           } | tr -d '\r' | sed '/^$/d' | sort -u)

  case "$rexists:$merged" in
    no:*)        verdict=REPAIR-BRANCH-MISSING; missing=$((missing+1)) ;;
    *:yes)       verdict=LANDED; landed=$((landed+1)) ;;
    *)           if [ "$gh_ok" != 1 ]; then verdict=UNLANDED-NO-GITHUB-REMOTE; norem=$((norem+1))
                 elif [ "${pr#\#}" != "$pr" ]; then verdict=UNLANDED-WITH-PR; upr=$((upr+1))
                 else verdict=UNLANDED-NO-PR; unopr=$((unopr+1)); fi ;;
  esac
  if [ "$merged" = yes ] && [ "$fvd" = 0 ] && [ "$fvr" != NA ] && [ "$fvr" != 0 ]; then
    verdict="$verdict|MERGED-BUT-ARTIFACT-ABSENT"; absent=$((absent+1))
  fi
  if [ "$pr" != none ] && [ "$prbase" != - ] && [ "$prbase" != "$defb" ]; then
    verdict="$verdict|PR-BASE-NOT-DEFAULT"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$app" "$repo" "$repokind" "$remote" "$defb" "$defby" "$checked" "$rb" "$rexists" "$merged" \
    "$ahead" "$pr" "$prbase" "$wt" "$fvd" "$fvr" "$rme" "$other" "$verdict" >> "$OUT"
done

echo "landed-sweep $DATE: units=$t landed=$landed unlanded-with-pr=$upr unlanded-no-pr=$unopr unlanded-no-github-remote=$norem repair-branch-missing=$missing merged-but-artifact-absent=$absent -> $OUT"
