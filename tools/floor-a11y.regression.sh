#!/usr/bin/env bash
# Regression case for the Appendix A accessibility blind spot: focus styling and
# dark mode written as Tailwind VARIANT PREFIXES in markup were invisible to the
# measurement, so a Tailwind app scored 0/0 and read as a floor FAILURE it did
# not have. Run with `old` to see it fail against the pre-correction rule.
#
# The fixture is deliberately built so the old rule sees NOTHING: its stylesheet
# contains no `:focus-visible` and no `prefers-color-scheme`, and every real
# signal lives in a class attribute in a `.jsx`, a `.tsx`, and a template
# literal inside a `server.js` (the shape of `168-audit` and
# `conference-tracker`, which the old file filter never opened at all).
#
# usage: floor-a11y.regression.sh [new|old]
set -u
here="$(cd "$(dirname "$0")" && pwd)"
which="${1:-new}"
script="$here/floor-a11y.sh"; [ "$which" = old ] && script="$here/floor-a11y-old.sh"

fix=$(mktemp -d); trap 'rm -rf "$fix"' EXIT
mkdir -p "$fix/app" "$fix/components"

# No `:focus-visible`, no `prefers-color-scheme`. The old rule's whole universe.
cat > "$fix/app/globals.css" <<'EOF'
:root { --bg: #fff; --fg: #111 }
body { background: var(--bg); color: var(--fg) }
button:focus { outline: none }
EOF

cat > "$fix/components/Panel.jsx" <<'EOF'
export default function Panel() {
  return (
    <div className="dark:bg-slate-900 dark:text-slate-200">
      <button className="focus:outline-none focus-visible:ring-2 focus-visible:ring-cobalt">a</button>
      <button className="group-focus-visible:ring-2">stacked variant, counted once</button>
      <a className="md:dark:bg-black">stacked dark variant, counted once</a>
    </div>
  );
}
EOF

cat > "$fix/components/Tile.tsx" <<'EOF'
export const Tile = () => (
  <b className="focus-visible:outline-2 !py-2">v3 prefix-important, invisible to the old grep</b>
);
EOF

# The `168-audit` / `conference-tracker` shape: the whole UI in a template
# literal inside a Node server. The old file filter never opened this file.
cat > "$fix/server.js" <<'EOF'
const page = `
  <main class="dark:bg-zinc-950">
    <input class="focus-visible:ring-1" />
  </main>`;
require('http').createServer((_, r) => r.end(page)).listen(3000);
EOF

( cd "$fix" && git init -q . && git add -A && git -c user.email=a@b -c user.name=a commit -qm f )

# focus: 5 variants — focus-visible:ring-2, focus-visible:ring-cobalt,
#        group-focus-visible:ring-2, focus-visible:outline-2,
#        focus-visible:ring-1 (in server.js). Zero CSS-form. `focus:outline-none`
#        is NOT counted (rule A2) and is reported as focus-only.
# dark:  4 variants — dark:bg-slate-900, dark:text-slate-200, md:dark:bg-black,
#        dark:bg-zinc-950. Zero CSS-form.
expected_focus=5
expected_dark=4
# `!py-2` is a Tailwind v3 important-prefix utility (rule A5). The old rule's
# `!important` grep cannot see it; the fixture's CSS has none, so old=0 new=1.
expected_important=1

out=$(bash "$script" "$fix" --detail 2>/dev/null)
[ -z "$out" ] && out=$(bash "$script" "$fix" 2>/dev/null)
g() { echo "$out" | tr ' ' '\n' | sed -n "s/^$1=//p" | head -1; }
gf=$(g focus); gf=${gf:-0}
gd=$(g dark);  gd=${gd:-0}
gi=$(g important-tw); gi=${gi:-0}

echo "fixture: 0 focus-visible and 0 prefers-color-scheme in CSS; 5 focus-visible"
echo "         and 4 dark variants in .jsx, .tsx and a server.js template literal"
echo "expected focus=$expected_focus dark=$expected_dark important-tw=$expected_important"
echo "got      focus=$gf dark=$gd important-tw=$gi  (script: $(basename "$script"))"
echo "full:    $out"
if [ "$gf" = "$expected_focus" ] && [ "$gd" = "$expected_dark" ] && [ "$gi" = "$expected_important" ]; then
  echo PASS; exit 0
else
  echo FAIL; exit 1
fi
