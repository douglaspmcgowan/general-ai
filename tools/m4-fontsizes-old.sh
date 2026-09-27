#!/usr/bin/env bash
# Frozen copy of the ORIGINAL Appendix A `m4` distinct-font-sizes measurement.
# Kept only so the correction in m4.sh stays auditable and the regression case
# can be shown failing against the old rule. Do not use it to take a number.
#
# usage: m4-fontsizes-old.sh <root>
set -u
root="${1:?usage: m4-fontsizes-old.sh <root>}"
root="${root%/}"

if [ -e "$root/.git" ]; then
  L=$(cd "$root" && git ls-files | sed "s#^#$root/#")
else
  L=$(find "$root" -type f | grep -v '/node_modules/')
fi

F=$(echo "$L" | grep -E '\.(css|html)$' | grep -vE '/\.next|/dist/|/out/|/\.agents/|\.min\.css$|/coverage/|/\.tmp-')
[ -z "$F" ] && { echo 0; exit 0; }
A=$(echo "$F" | xargs -d'\n' cat 2>/dev/null)
echo "$A" | grep -oiE 'font-size: *[^;}"]*' | sed 's/.*: *//' | sort -u | grep -c .
