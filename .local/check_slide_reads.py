"""Gate for SC22 slide reads: reject placeholder records so a lane cannot claim coverage it did not do.

Usage: python check_slide_reads.py <staging root> [--quarantine <dir>]
A post fails when images_expected disagrees with the capture, when a jpg on disk has no slide record,
or when any slide record is a placeholder (generic "reviewed" wording, or empty text and empty visual).
With --quarantine, failing post files are moved there so a resumable lane redoes them.
"""
import collections
import json
import pathlib
import re
import shutil
import sys

PLACEHOLDER = re.compile(r"(transcription (remains|is) (incomplete|partial)|no transcription recorded|remains to be completed|"
                         r"^(image|slide image|viewed image|inspected slide image)[^.]{0,40}(reviewed|opened|viewed)[;.]|"
                         r"machine-readable text layer|a downloaded instagram slide|^post [\w-]{8,}, slide \d+)", re.I)


def expected_images(post):
    if post["slides"]:
        return sum(1 for s in post["slides"] if s.get("img"))
    return 1 if post.get("img") else 0


def check(root):
    capture = json.loads((root / "browser" / "ig-capture-20260923.json").read_text(encoding="utf-8"))
    failures, visuals = {}, collections.Counter()
    for post in capture["posts"]:
        sc, want = post["sc"], expected_images(post)
        if not want:
            continue
        path = root / "classification" / "slides" / f"{sc}.json"
        if not path.exists():
            failures[sc] = "missing"
            continue
        try:
            rec = json.loads(path.read_text(encoding="utf-8"))
        except ValueError:
            failures[sc] = "unparseable"
            continue
        on_disk = sorted(p.name for p in (root / "media" / sc).glob("*.jpg"))
        files = [s.get("file") for s in rec.get("slides", [])]
        why = []
        if rec.get("images_expected") != want:
            why.append(f"images_expected {rec.get('images_expected')} != capture {want}")
        if sorted(f for f in files if f in on_disk) != on_disk:
            why.append("jpg without a slide record")
        for s in rec.get("slides", []):
            visual, text = (s.get("visual") or "").strip(), (s.get("text") or "").strip()
            visuals[visual] += 1
            if PLACEHOLDER.search(visual) or (not visual and not text):
                why.append(f"placeholder {s.get('file')}")
        if why:
            failures[sc] = "; ".join(why[:3]) + (f" (+{len(why) - 3})" if len(why) > 3 else "")
    repeated = {v: n for v, n in visuals.items() if v and n >= 15}
    return failures, repeated


def main():
    root = pathlib.Path(sys.argv[1])
    failures, repeated = check(root)
    if "--quarantine" in sys.argv:
        dest = pathlib.Path(sys.argv[sys.argv.index("--quarantine") + 1])
        dest.mkdir(parents=True, exist_ok=True)
        for sc in failures:
            src = root / "classification" / "slides" / f"{sc}.json"
            if src.exists():
                shutil.move(str(src), str(dest / src.name))
    print(f"failing_posts={len(failures)}")
    for sc, why in sorted(failures.items())[:40]:
        print(f"  {sc}: {why}")
    print(f"visuals_repeated_15plus={len(repeated)}")
    for v, n in sorted(repeated.items(), key=lambda kv: -kv[1])[:10]:
        print(f"  {n}x {v[:90]}")
    sys.exit(1 if failures or repeated else 0)


if __name__ == "__main__":
    main()
