#!/usr/bin/env bash
# Appendix A floor measurement for the accessibility properties that a
# Tailwind-first app writes in MARKUP rather than in a stylesheet.
#
# Corrected 2026-09-27. The previous rule grepped committed `.css`/`.html` for
# the pseudo-class `:focus-visible` and the at-rule `prefers-color-scheme`. A
# Tailwind app writes neither. It writes `focus-visible:ring-2` and
# `dark:bg-slate-900` as VARIANT PREFIXES inside class attributes in markup. So
# those apps scored zero and read as a floor FAILURE they do not have. That is
# the inverse of the font-size defect in m4.sh and strictly worse: a false pass
# wastes nothing, a false failure sends an agent to redo finished work.
#
# Counting rules (see APP-REPAIR-SPEC.md, Appendix A):
#   A1 file set   the same `.css`/`.html` set as before, plus every committed
#                 markup or component file, identical to m4.sh R1:
#                 .jsx .tsx .js .ts .mjs .cjs .vue .svelte .astro .mdx .php .erb
#                 (this is also what opens `168-audit` and `conference-tracker`,
#                 whose entire UI is a template literal inside `server.js`)
#   A2 focus      focus = CSS-form `:focus-visible` occurrences
#                       + markup-form `focus-visible:` variant occurrences.
#                 VERDICT B2 passes at >= 1 — the published threshold, unchanged.
#                 Bare `focus:` (not focus-visible) is reported separately as
#                 `focus-only` and does NOT satisfy B2: B2 names the
#                 focus-visible behaviour, and `focus:outline-none` alone is the
#                 defect B2 exists to catch.
#   A3 dark       dark = CSS-form `prefers-color-scheme` occurrences
#                       + markup-form `dark:` variant occurrences.
#                 VERDICT B4 passes only when a dark treatment reaches the page
#                 SURFACE: a `prefers-color-scheme:...dark` block, or at least
#                 one background-establishing dark variant (`dark:bg-`,
#                 `dark:from-`/`via-`/`to-`, or `dark:[--token:`). One
#                 `dark:text-*` with no dark surface leaves the page white in
#                 dark mode, so it is a token slip, not dark-mode support.
#                 Reported as `dark-surface=yes|no` next to the raw count.
#   A4 mechanism  Tailwind v4 `@custom-variant dark` and v3 `darkMode: 'class'`
#                 change what `dark:` resolves against (a class, not the media
#                 query). Reported as `dark-mechanism=media|class|none` so a
#                 class-strategy app with no toggle code is visible rather than
#                 silently counted as supporting dark mode.
#   A5 important  B5 is "zero `!important`". Tailwind writes it as a `!` prefix
#                 (v3, `!text-red-500`) or a `!` suffix (v4, `text-red-500!`),
#                 neither of which contains the string `!important`. Counted.
#   A6 tokens     custom properties `--name:` over the WHOLE file set, so tokens
#                 declared in a JSX style object or a template literal count.
#   A7 occurrences  every count here is OCCURRENCES, not matching lines. The old
#                 rule used `grep -c`, which counts lines: a minified sheet with
#                 nine `:focus-visible` rules on one line scored 1. Where the
#                 old and new numbers must be compared like for like, the
#                 blast-radius table shows both and only the VERDICT is compared.
#
# usage: floor-a11y.sh <root> [--detail]
#   (no flag)  focus=N dark=N
#   --detail   everything
set -u
root="${1:?usage: floor-a11y.sh <root> [--detail]}"
root="${root%/}"
mode="${2:-short}"

if [ -e "$root/.git" ]; then
  L=$(cd "$root" && git ls-files 2>/dev/null | sed "s#^#$root/#")
else
  L=$(find "$root" -type f 2>/dev/null | grep -v '/node_modules/')
fi

EXCLUDE='/\.next|/dist/|/out/|/\.agents/|\.min\.css$|\.min\.js$|/coverage/|/\.tmp-|/node_modules/|/\.git/'

# A1(a) — the original stylesheet/page set, unchanged.
F_CSS=$(echo "$L" | grep -E '\.(css|html|htm)$' | grep -vE "$EXCLUDE")
# A1(b) — the set the old rule could not see.
F_MARKUP=$(echo "$L" | grep -E '\.(jsx|tsx|js|ts|mjs|cjs|vue|svelte|astro|mdx|php|erb)$' | grep -vE "$EXCLUDE")
# A4 — Tailwind configuration, wherever it lives.
F_CFG=$(echo "$L" | grep -E '(tailwind\.config\.(js|cjs|mjs|ts)|\.css)$' | grep -vE "$EXCLUDE")

read_set() { [ -z "$1" ] && return 0; echo "$1" | xargs -d'\n' cat 2>/dev/null; }

CSS=$(read_set "$F_CSS")
MARKUP=$(read_set "$F_MARKUP")
ALL=$( { printf '%s\n' "$CSS"; printf '%s\n' "$MARKUP"; } )
CFG=$(read_set "$F_CFG")

n() { if [ -z "$1" ]; then echo 0; else echo "$1" | grep -c .; fi; }

# ---- A2 focus ----------------------------------------------------------------
# CSS form: `:focus-visible` as a pseudo-class, over the whole file set (a
# styled-components or template-literal stylesheet lives in a markup file).
FOC_CSS=$(n "$(echo "$ALL" | grep -oE ':focus-visible')")
# Markup form: a variant prefix `focus-visible:` NOT preceded by `:`, which
# would be the CSS pseudo-class followed by another pseudo-class.
FOC_VAR=$(n "$(echo "$MARKUP" | grep -oE '(^|[^:A-Za-z0-9_])focus-visible:')")
FOCUS=$((FOC_CSS + FOC_VAR))
# Reported, never counted toward B2.
FOC_ONLY=$(n "$(echo "$ALL" | grep -oE '(^|[^:A-Za-z0-9_])focus:')")

# ---- A3 dark ----------------------------------------------------------------
DRK_CSS=$(n "$(echo "$ALL" | grep -oE 'prefers-color-scheme')")
DRK_VAR=$(n "$(echo "$MARKUP" | grep -oE '(^|[^-A-Za-z0-9_])dark:[a-zA-Z[]')")
DARK=$((DRK_CSS + DRK_VAR))

SURF=no
if echo "$ALL" | grep -qE 'prefers-color-scheme[^)]*dark'; then SURF=yes; fi
if echo "$MARKUP" | grep -qE '(^|[^-A-Za-z0-9_])dark:(bg-|from-|via-|to-|\[--)'; then SURF=yes; fi

# ---- A4 mechanism -----------------------------------------------------------
MECH=none
if [ "$DARK" -gt 0 ]; then MECH=media; fi
if echo "$CFG" | grep -qE 'darkMode[[:space:]]*:[[:space:]]*\[?.(class|selector)'; then MECH=class; fi
if echo "$CSS" | grep -qE '@custom-variant[[:space:]]+dark'; then MECH=class; fi

# ---- A5 !important ----------------------------------------------------------
IMP_CSS=$(n "$(echo "$ALL" | grep -oE '!important')")
# Tailwind v3 prefix `!text-red-500` / v4 suffix `text-red-500!`, matched only
# inside a class attribute, so a JS negation or a template placeholder is not
# swept in. Extract class attribute values first, then scan them.
CLASSVALS=$(echo "$MARKUP" | grep -oE 'class(Name)?[[:space:]]*=[[:space:]]*.[^>]{0,400}' || true)
# Only the v3 PREFIX form is counted, and only when the token is shaped like a
# Tailwind utility — at least one internal `-`, as in `!py-2`, `!normal-case`,
# `!pl-9`. Two exclusions, both measured rather than assumed:
#   * `!open`, `!isLoading` — JSX boolean negation inside `className={...}`. No
#     internal `-`, so the shape test drops it.
#   * the v4 SUFFIX form `text-red-500!` is NOT counted, because in this file set
#     it is indistinguishable from a TypeScript non-null assertion
#     (`className={styles.x!}`). Counting it took `bible-name-search` from 8 to
#     221, none of them real. If an app adopts the v4 suffix this rule
#     undercounts and must be revisited; no roster app does today.
B='[^-A-Za-z0-9_!]'
IMP_TW=$(n "$(echo "$CLASSVALS" \
  | grep -oE "(^|$B)![a-z][a-z0-9]*-[a-z0-9[][-A-Za-z0-9_:./%[]*")")
IMPORTANT=$((IMP_CSS + IMP_TW))

# ---- A6 tokens --------------------------------------------------------------
TOK=$(n "$(echo "$ALL" | grep -oE '\-\-[a-zA-Z0-9_-]+[[:space:]]*:' | sed -E 's/[[:space:]]*:$//' | sort -u)")

# ---- transition -------------------------------------------------------------
TRN_CSS=$(n "$(echo "$ALL" | grep -oE 'transition')")
TRN_VAR=$(n "$(echo "$MARKUP" | grep -oE '(^|[^-:A-Za-z0-9_])(transition|duration-|ease-)[a-z[-]')")

case "$mode" in
  --detail) echo "focus=$FOCUS focus-css=$FOC_CSS focus-variant=$FOC_VAR focus-only=$FOC_ONLY dark=$DARK dark-css=$DRK_CSS dark-variant=$DRK_VAR dark-surface=$SURF dark-mechanism=$MECH important=$IMPORTANT important-css=$IMP_CSS important-tw=$IMP_TW tokens=$TOK transition-css=$TRN_CSS transition-variant=$TRN_VAR" ;;
  *)        echo "focus=$FOCUS dark=$DARK" ;;
esac
