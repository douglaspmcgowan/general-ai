#!/usr/bin/env bash
# Runs the old and the corrected accessibility-floor measurement over every
# roster row in APP-REPAIR-SPEC.md and prints the blast-radius table, including
# the column that matters: whether the floor VERDICT changes.
#
#   B2 focus verdict  PASS at focus >= 1 (threshold unchanged; only the file set
#                     and the markup-variant form are new)
#   B4 dark verdict   OLD: PASS at any `prefers-color-scheme` hit
#                     NEW: PASS only when a dark treatment reaches the page
#                     surface (floor-a11y.sh rule A3)
#
# usage: floor-a11y-blast-radius.sh [roots-file]
set -u
here="$(cd "$(dirname "$0")" && pwd)"
P=/c/Users/dougl/Projects
roots_file="${1:-$here/m4-roster-roots.tsv}"

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  app old_focus new_focus focus_verdict old_dark new_dark dark_surface dark_verdict important_new
while IFS=$'\t' read -r name path; do
  [ -z "${name:-}" ] && continue
  case "$name" in \#*) continue;; esac
  root="$P/$path"
  if [ ! -d "$root" ]; then printf '%s\tMISSING\t-\t-\t-\t-\t-\t-\t-\n' "$name"; continue; fi
  o=$(bash "$here/floor-a11y-old.sh" "$root" 2>/dev/null)
  nw=$(bash "$here/floor-a11y.sh" "$root" --detail 2>/dev/null)
  g() { echo "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -1; }
  of=$(g "$o" focus);    of=${of:-0}
  od=$(g "$o" dark);     od=${od:-0}
  nf=$(g "$nw" focus);   nf=${nf:-0}
  nd=$(g "$nw" dark);    nd=${nd:-0}
  ns=$(g "$nw" dark-surface); ns=${ns:-no}
  ni=$(g "$nw" important);    ni=${ni:-0}

  ofv=FAIL; [ "$of" -ge 1 ] && ofv=PASS
  nfv=FAIL; [ "$nf" -ge 1 ] && nfv=PASS
  fv=same;  [ "$ofv" != "$nfv" ] && fv="$ofv->$nfv"

  odv=FAIL; [ "$od" -ge 1 ] && odv=PASS
  ndv=FAIL; [ "$ns" = yes ]  && ndv=PASS
  dv=same;  [ "$odv" != "$ndv" ] && dv="$odv->$ndv"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$name" "$of" "$nf" "$fv" "$od" "$nd" "$ns" "$dv" "$ni"
# the roster file is CRLF on this host; strip CR or every path misses by one byte
done < <(tr -d "\r" < "$roots_file")
