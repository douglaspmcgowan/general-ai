#!/usr/bin/env bash
# Appendix A measurement m4 — distinct font sizes live in one app unit.
#
# Corrected 2026-09-27. The previous rule grepped `font-size:` in committed
# `.css` and `.html` only. In a Tailwind-first app most sizes are never written
# as a `font-size` declaration and never appear in a stylesheet at all: they are
# arbitrary utilities inside class attributes in `.jsx`/`.tsx`. For
# `bible-name-search` the old rule saw 12 of 51. A measurement that cannot see
# three quarters of its subject reads as a pass, so it was worse than none.
#
# Counting rules (see APP-REPAIR-SPEC.md, Appendix A):
#   R1 file set    declared sizes are read from the same `.css`/`.html` set as
#                  before, plus every committed markup or component file:
#                  .jsx .tsx .js .ts .mjs .cjs .vue .svelte .astro .mdx .php .erb
#   R2 sources     (a) `font-size:` / `fontSize:` declarations, anywhere,
#                      including inline `style=` and JSX style objects;
#                  (b) Tailwind arbitrary utilities `text-[<value>]`, including
#                      variant- and important-prefixed forms, but only when the
#                      value is a LENGTH. `text-` is overloaded in Tailwind:
#                      `text-[var(--text-1)]` and `text-[#fff]` are colours.
#                      `text-[length:var(--x)]` is an explicit length and counts.
#   R3 units       px and pt are converted to rem at the default 16px root, so
#                  0.625rem and 10px are one size, not two. Relative and
#                  viewport units (em, %, vw, ch, ...) are NOT collapsed into
#                  rem: their rendered size depends on context, so calling them
#                  equal would be a guess.
#   R4 dedupe      one normalised set for the whole app unit; a size repeated in
#                  forty files counts once.
#   R5 named steps `text-sm`, `text-lg` and friends are NOT counted in the
#                  total. They are reported separately as `named-steps`. m4
#                  measures scale DRIFT — sizes invented outside the system. A
#                  named step is on the system's scale by construction; forty
#                  uses of `text-sm` are one decision, while `text-[0.82rem]`
#                  and `text-[0.83rem]` are two.
#
# usage: m4.sh <root> [--list] [--detail]
#   (no flag)  one integer: distinct font sizes
#   --list     the normalised sizes, one per line, then the integer
#   --detail   `distinct=N declared=N arbitrary=N named-steps=N`
set -u
root="${1:?usage: m4.sh <root> [--list|--detail]}"
root="${root%/}"
mode="${2:-count}"

if [ -e "$root/.git" ]; then
  L=$(cd "$root" && git ls-files 2>/dev/null | sed "s#^#$root/#")
else
  L=$(find "$root" -type f 2>/dev/null | grep -v '/node_modules/')
fi

EXCLUDE='/\.next|/dist/|/out/|/\.agents/|\.min\.css$|\.min\.js$|/coverage/|/\.tmp-|/node_modules/|/\.git/'

# R1(a) — the original stylesheet/page set, unchanged.
F_CSS=$(echo "$L" | grep -E '\.(css|html|htm)$' | grep -vE "$EXCLUDE")
# R1(b) — the set the old rule could not see.
F_MARKUP=$(echo "$L" | grep -E '\.(jsx|tsx|js|ts|mjs|cjs|vue|svelte|astro|mdx|php|erb)$' | grep -vE "$EXCLUDE")

read_set() { [ -z "$1" ] && return 0; echo "$1" | xargs -d'\n' cat 2>/dev/null; }

ALL=$( { read_set "$F_CSS"; read_set "$F_MARKUP"; } )
MARKUP=$(read_set "$F_MARKUP")
HTMLISH=$( { read_set "$F_CSS"; read_set "$F_MARKUP"; } )

norm() {
  # stdin: raw values -> stdout: normalised values
  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
      -e "s/^['\"\`]//" -e "s/['\"\`]\$//" \
      -e 's/[[:space:]]//g' \
      -e 's/^length://' \
  | tr 'A-Z' 'a-z' \
  | awk '
      $0=="" { next }
      {
        v=$0
        if (v ~ /^-?[0-9]*\.?[0-9]+px$/)      { n=v+0; v=sprintf("%.6f", n/16)   "rem"; }
        else if (v ~ /^-?[0-9]*\.?[0-9]+pt$/) { n=v+0; v=sprintf("%.6f", n*4/3/16) "rem"; }
        if (v ~ /^-?[0-9]*\.?[0-9]+(rem|em)$/) {
          u=v; sub(/^-?[0-9]*\.?[0-9]+/,"",u); n=v+0;
          s=sprintf("%.6f", n); sub(/0+$/,"",s); sub(/\.$/,"",s);
          v=s u;
        }
        print v
      }'
}

# (a) declared sizes. Three shapes, because one regex cannot hold them all:
#     CSS `font-size: clamp(a, b, c);`  -> `,` and `)` must stay inside the value
#     JSX `fontSize: '0.82rem'`          -> the value is quoted
#     JSX `fontSize: 14`                 -> unitless, px by React's rule
D_CSS=$(echo "$ALL" | grep -oiE 'font-size[[:space:]]*:[[:space:]]*[^;}"'"'"'`]*' \
        | sed -E 's/^[^:]*:[[:space:]]*//')
D_JSX=$(echo "$MARKUP" | grep -oE 'fontSize[[:space:]]*:[[:space:]]*['"'"'"`][^'"'"'"`]*['"'"'"`]' \
        | sed -E 's/^[^:]*:[[:space:]]*//')
D_NUM=$(echo "$MARKUP" | grep -oE 'fontSize[[:space:]]*:[[:space:]]*[0-9]+\.?[0-9]*[,}[:space:]]' \
        | grep -oE '[0-9]+\.?[0-9]*' | sed 's/$/px/')
DECLARED=$(printf '%s\n%s\n%s\n' "$D_CSS" "$D_JSX" "$D_NUM" | norm | grep -v '^$' | sort -u)

# (b) Tailwind arbitrary values, length-valued only
ARB=$(echo "$HTMLISH" | grep -oE '(^|[^a-zA-Z0-9_-])!?text-\[[^]]*\]' \
      | grep -oE 'text-\[[^]]*\]' | sed -E 's/^text-\[//; s/\]$//' \
      | grep -E '^(length:|clamp\(|calc\(|min\(|max\(|-?[0-9]*\.?[0-9]+(px|rem|em|pt|%|vw|vh|vmin|vmax|ch|ex|cm|mm|in|pc|q)$)' \
      | norm | grep -v '^$' | sort -u)

# R5 — named steps, reported but not counted
NAMED=$(echo "$HTMLISH" | grep -oE '(^|[^a-zA-Z0-9_-])!?text-(xs|sm|base|lg|xl|[2-9]xl)($|[^a-zA-Z0-9_-])' \
        | grep -oE 'text-(xs|sm|base|lg|xl|[2-9]xl)' | sort -u)

UNION=$(printf '%s\n%s\n' "$DECLARED" "$ARB" | grep -v '^$' | sort -u)

c() { [ -z "$1" ] && echo 0 || (echo "$1" | grep -c .); }

case "$mode" in
  --list)   echo "$UNION"; c "$UNION" ;;
  --detail) echo "distinct=$(c "$UNION") declared=$(c "$DECLARED") arbitrary=$(c "$ARB") named-steps=$(c "$NAMED")" ;;
  *)        c "$UNION" ;;
esac
