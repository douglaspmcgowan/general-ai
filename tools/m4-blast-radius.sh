#!/usr/bin/env bash
# Runs the old and the corrected m4 distinct-font-sizes measurement over every
# roster row in APP-REPAIR-SPEC.md and prints the blast-radius table.
# usage: m4-blast-radius.sh [roots-file]
set -u
here="$(cd "$(dirname "$0")" && pwd)"
P=/c/Users/dougl/Projects
roots_file="${1:-$here/m4-roster-roots.tsv}"

printf '%s\t%s\t%s\t%s\t%s\t%s\n' app reported true diff declared arbitrary
while IFS=$'\t' read -r name path; do
  [ -z "${name:-}" ] && continue
  case "$name" in \#*) continue;; esac
  root="$P/$path"
  if [ ! -d "$root" ]; then printf '%s\tMISSING\t-\t-\t-\t-\n' "$name"; continue; fi
  old=$(bash "$here/m4-fontsizes-old.sh" "$root" 2>/dev/null); old=${old:-0}
  det=$(bash "$here/m4.sh" "$root" --detail 2>/dev/null)
  new=$(echo "$det" | sed -n 's/.*distinct=\([0-9]*\).*/\1/p'); new=${new:-0}
  dec=$(echo "$det" | sed -n 's/.*declared=\([0-9]*\).*/\1/p'); dec=${dec:-0}
  arb=$(echo "$det" | sed -n 's/.*arbitrary=\([0-9]*\).*/\1/p'); arb=${arb:-0}
  printf '%s\t%s\t%s\t%+d\t%s\t%s\n' "$name" "$old" "$new" "$((new-old))" "$dec" "$arb"
done < "$roots_file"
