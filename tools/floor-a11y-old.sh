#!/usr/bin/env bash
# Frozen copy of the ORIGINAL Appendix A rule for the two accessibility-floor
# properties B2 (`:focus-visible`) and B4 (`prefers-color-scheme` dark), plus
# the two neighbours checked for the same blind spot, B5 (`!important`) and
# B1 (custom properties), and the `transition` count.
#
# Kept only so the correction in floor-a11y.sh stays auditable and the
# regression case can be shown failing against it. Do not take a number from it.
#
# usage: floor-a11y-old.sh <root>
#   stdout: focus=N dark=N important=N tokens=N transition=N
set -u
root="${1:?usage: floor-a11y-old.sh <root>}"
root="${root%/}"

if [ -e "$root/.git" ]; then
  L=$(cd "$root" && git ls-files 2>/dev/null | sed "s#^#$root/#")
else
  L=$(find "$root" -type f 2>/dev/null | grep -v '/node_modules/')
fi

F=$(echo "$L" | grep -E '\.(css|html)$' | grep -vE '/\.next|/dist/|/out/|/\.agents/|\.min\.css$|/coverage/|/\.tmp-')
if [ -z "$F" ]; then echo "focus=0 dark=0 important=0 tokens=0 transition=0"; exit 0; fi
A=$(echo "$F" | xargs -d'\n' cat 2>/dev/null)

# The published rule: `grep -c <pattern>` — MATCHING LINES, not occurrences.
foc=$(echo "$A" | grep -c ':focus-visible')
drk=$(echo "$A" | grep -c 'prefers-color-scheme')
imp=$(echo "$A" | grep -c '!important')
trn=$(echo "$A" | grep -c 'transition')
tok=$(echo "$A" | grep -oE '\-\-[a-zA-Z0-9_-]+ *:' | sed 's/ *:$//' | sort -u | grep -c .)
echo "focus=$foc dark=$drk important=$imp tokens=$tok transition=$trn"
