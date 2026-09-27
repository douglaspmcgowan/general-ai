#!/usr/bin/env bash
# Regression case for the Appendix A m4 blind spot: font sizes written as
# Tailwind arbitrary utilities inside JSX class names were invisible to the
# measurement. Run with `old` to see it fail against the pre-correction rule.
#
# usage: m4.regression.sh [new|old]
set -u
here="$(cd "$(dirname "$0")" && pwd)"
which="${1:-new}"
script="$here/m4.sh"; [ "$which" = old ] && script="$here/m4-fontsizes-old.sh"

fix=$(mktemp -d); trap 'rm -rf "$fix"' EXIT
mkdir -p "$fix/app" "$fix/components"
cat > "$fix/app/globals.css" <<'EOF'
:root { --x: 1rem }
body { font-size: 0.6875rem }
h1 { font-size: 15px }
EOF
cat > "$fix/components/Panel.jsx" <<'EOF'
export default function Panel() {
  return (
    <div className="text-[0.82rem] sm:text-[0.83rem]">
      <p className="text-[0.855rem] font-medium">a</p>
      <p className="text-[0.875rem]">b</p>
      <p className="text-sm">named step, not a distinct size</p>
      <p className="text-[var(--jade-hi)]">a colour, not a size</p>
      <p className="text-[0.625rem]">collapses with 10px</p>
      <span style={{ fontSize: '1.4rem' }}>inline</span>
    </div>
  );
}
EOF
cat > "$fix/components/Tile.tsx" <<'EOF'
export const Tile = () => <b className="text-[0.82rem] text-[10px]">dup + px</b>;
EOF
( cd "$fix" && git init -q . && git add -A && git -c user.email=a@b -c user.name=a commit -qm f )

# 0.6875rem, 0.9375rem(15px), 0.82rem, 0.83rem, 0.855rem, 0.875rem,
# 0.625rem(==10px), 1.4rem  -> 8. text-sm and text-[var(--jade-hi)] excluded.
expected=8
got=$(bash "$script" "$fix")
echo "fixture: 2 sizes declared in CSS, 5 more in JSX class names and 1 in a JSX style object"
echo "expected=$expected got=$got  (script: $(basename "$script"))"
if [ "$got" = "$expected" ]; then echo "PASS"; exit 0; else echo "FAIL"; exit 1; fi
