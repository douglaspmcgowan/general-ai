"""Fetch public post media named in a capture file into gitignored staging, for slide reading and transcription.

Images go to media/<shortcode>/slide-NN.jpg (or cover.jpg), video posts to media/<shortcode>/video.mp4 plus
audio.m4a, and video slides to media/<shortcode>/slide-NN.m4a. Existing files are skipped, so a rerun resumes.
"""
import concurrent.futures as cf
import json
import pathlib
import subprocess
import sys
import urllib.request

UA = {"User-Agent": "Mozilla/5.0"}


def get(url, dest):
    if dest.exists() and dest.stat().st_size > 0:
        return "skip"
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=120) as r, open(dest.with_suffix(dest.suffix + ".part"), "wb") as f:
        while chunk := r.read(1 << 16):
            f.write(chunk)
    dest.with_suffix(dest.suffix + ".part").replace(dest)
    return "ok"


def audio(src, dest):
    if dest.exists() and dest.stat().st_size > 0:
        return "skip"
    p = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", str(src), "-vn", "-c:a", "aac", "-b:a", "96k", str(dest)],
                       capture_output=True, text=True)
    return "ok" if p.returncode == 0 and dest.exists() else "no-audio"


def jobs(capture, root):
    for p in capture["posts"]:
        d = root / p["sc"]
        if p["slides"]:
            for i, s in enumerate(p["slides"], 1):
                if s["img"]:
                    yield ("img", s["img"], d / f"slide-{i:02d}.jpg", None)
                if s["vid"] and s.get("aud") is not False:
                    yield ("vid", s["vid"], d / f"slide-{i:02d}.mp4", d / f"slide-{i:02d}.m4a")
        else:
            if p["img"]:
                yield ("img", p["img"], d / "cover.jpg", None)
            if p["vid"]:
                yield ("vid", p["vid"], d / "video.mp4", d / "audio.m4a" if p.get("aud") is not False else None)


def run(job):
    kind, url, dest, aud = job
    try:
        r = get(url, dest)
        if kind == "vid" and aud:
            a = audio(dest, aud)
            if dest.name.startswith("slide-"):
                dest.unlink(missing_ok=True)  # slide videos: keep audio and the slide image only
            return (str(dest), r, a)
        return (str(dest), r, None)
    except Exception as e:  # noqa: BLE001 - report every failure, never stop the batch
        return (str(dest), "error", repr(e)[:200])


def main():
    capture = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    root = pathlib.Path(sys.argv[2])
    results = list(cf.ThreadPoolExecutor(8).map(run, list(jobs(capture, root))))
    (root / "fetch-report.json").write_text(json.dumps(results, indent=1), encoding="utf-8")
    from collections import Counter
    print("FETCH", Counter(r[1] for r in results), "AUDIO", Counter(r[2] for r in results if r[2] is not None))


if __name__ == "__main__":
    main()
