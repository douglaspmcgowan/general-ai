// Recital / legal-doc-studio — computed-style parity probe.
// Run in the page at http://127.0.0.1:8911/ with the browser tab at its DEFAULT
// pane size (the Stage 1 capture was taken at innerWidth 1024 x innerHeight 768,
// where the .rail and .ctx panels are display:none behind the app's own breakpoint).
// Compare the JSON it returns against legal-doc-studio.computed-style.before.json.
// Any difference after a token extraction means the change was NOT non-visual.
const sel = ['body','.topbar','.brand__name','.rail','.rail__title','.paper','.stage','.ctx','.ctx__tab','.btn','.segmented button','.progress__fill','.form','#paper','.mobilenote'];
const props = ['color','backgroundColor','borderColor','fontFamily','fontSize','fontWeight','lineHeight','letterSpacing','padding','margin','borderRadius','boxShadow','width','height','display','gap'];
const out = {};
for (const s of sel) {
  const el = document.querySelector(s);
  if (!el) { out[s] = 'ABSENT'; continue; }
  const cs = getComputedStyle(el);
  out[s] = Object.fromEntries(props.map(p => [p, cs[p]]));
}
out.__count = document.querySelectorAll('*').length;
out.__viewport = window.innerWidth + 'x' + window.innerHeight;
JSON.stringify(out, null, 2)
