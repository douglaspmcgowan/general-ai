import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parent
SCRIPT = HERE / "publish_social_corpus.py"
GEO_NAME = "geo_grandmasters — AI surveillance and commercial power — DZ7sxpHyfzu.md"


def run_cli(source: Path, vault: Path, *args: str):
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--source", str(source), "--vault-root", str(vault), *args],
        cwd=HERE,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def write(path: Path, content: bytes):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)


class PublisherTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="social-publisher-")
        self.root = Path(self.tmp.name)
        self.source = self.root / "source"
        self.vault = self.root / "vault"
        write(self.source / "00 - Saved AI Posts Corpus Index.md", b"---\nauthored_by: agent\n---\nindex\n")
        write(self.source / "Notes" / "alpha.md", b"---\nauthored_by: agent\n---\nalpha-v1\n")
        write(self.source / "Notes" / "nested" / "beta.bin", bytes(range(32)))
        write(self.source / "Images" / "project.png", b"\x89PNG\r\nfixture")
        write(self.source / "Backups" / "do-not-copy.md", b"backup")
        write(self.source / "Notes" / "Backups" / "nested-backup.md", b"backup")
        write(self.source / "_review" / "review.md", b"review")
        write(self.source / "_evidence" / "evidence.md", b"evidence")
        for name in ("run-manifest.json", "CONTRACT-EVIDENCE.md", "Continuation plan and progress map.md"):
            write(self.source / name, b"staging-artifact")

    def tearDown(self):
        self.tmp.cleanup()

    def test_dry_run_writes_nothing_and_prints_exclusions(self):
        result = run_cli(self.source, self.vault)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.vault.exists())
        self.assertIn("MODE=dry-run", result.stdout)
        self.assertIn("CREATE Notes/alpha.md", result.stdout)
        self.assertIn("EXCLUDED_DIR=Backups/", result.stdout)
        self.assertIn("EXCLUDED_FILE=run-manifest.json", result.stdout)

    def test_apply_creates_then_updates_and_backs_up(self):
        first = run_cli(self.source, self.vault, "--apply")
        self.assertEqual(first.returncode, 0, first.stderr)
        target = self.vault / "50 Knowledge" / "57 Corpus" / "Saved AI Posts"
        self.assertEqual((target / "Notes" / "alpha.md").read_bytes(), b"---\nauthored_by: agent\n---\nalpha-v1\n")
        write(self.source / "Notes" / "alpha.md", b"---\nauthored_by: agent\n---\nalpha-v2\n")
        second = run_cli(self.source, self.vault, "--apply")
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual((target / "Notes" / "alpha.md").read_bytes(), b"---\nauthored_by: agent\n---\nalpha-v2\n")
        self.assertIn("UPDATE Notes/alpha.md", second.stdout)
        backup_lines = [line for line in second.stdout.splitlines() if line.startswith("BACKUP ")]
        self.assertTrue(backup_lines)
        backup = Path(backup_lines[0].split(" ", 1)[1])
        self.assertTrue(backup.is_file())
        self.assertEqual(backup.read_bytes(), b"---\nauthored_by: agent\n---\nalpha-v1\n")
        with self.assertRaises(ValueError):
            backup.relative_to(self.vault)

    def test_unchanged_files_keep_mtime(self):
        result = run_cli(self.source, self.vault, "--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        path = self.vault / "50 Knowledge" / "57 Corpus" / "Saved AI Posts" / "Notes" / "alpha.md"
        stamp = time.time_ns() - 10_000_000_000
        os.utime(path, ns=(stamp, stamp))
        before = path.stat().st_mtime_ns
        result = run_cli(self.source, self.vault, "--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(path.stat().st_mtime_ns, before)
        self.assertIn("UNCHANGED Notes/alpha.md", result.stdout)

    def test_human_authored_and_locked_targets_are_refused_byte_identical(self):
        target = self.vault / "50 Knowledge" / "57 Corpus" / "Saved AI Posts"
        human = b"---\nauthored_by: human\n---\nDouglas prose\n"
        locked = b"---\nauthored_by: agent\nlocked: true\n---\nlocked\n"
        write(target / "Notes" / "alpha.md", human)
        write(target / "Notes" / "nested" / "beta.bin", locked)
        result = run_cli(self.source, self.vault, "--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("REFUSE Notes/alpha.md", result.stdout)
        self.assertIn("REFUSE Notes/nested/beta.bin", result.stdout)
        self.assertEqual((target / "Notes" / "alpha.md").read_bytes(), human)
        self.assertEqual((target / "Notes" / "nested" / "beta.bin").read_bytes(), locked)

    def test_geo_note_is_never_modified_and_orphans_are_kept(self):
        target = self.vault / "50 Knowledge" / "57 Corpus" / "Saved AI Posts"
        geo = b"---\nauthored_by: agent\n---\noriginal geo\n"
        write(target / "Notes" / GEO_NAME, geo)
        write(target / "orphan.md", b"orphan")
        write(self.source / "Notes" / GEO_NAME, b"different source geo")
        before_hash = hashlib.sha256(geo).hexdigest()
        result = run_cli(self.source, self.vault, "--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(hashlib.sha256((target / "Notes" / GEO_NAME).read_bytes()).hexdigest(), before_hash)
        self.assertEqual((target / "orphan.md").read_bytes(), b"orphan")
        self.assertIn("orphan-kept orphan.md", result.stdout)
        self.assertIn("GEO_SHA256_BEFORE=" + before_hash, result.stdout)
        self.assertIn("GEO_SHA256_AFTER=" + before_hash, result.stdout)

    def test_each_excluded_vault_path_refuses_without_touching_it(self):
        import publish_social_corpus as publisher

        roots = [
            self.root / "AI Reference",
            self.root / "40_Reference" / "AI Reference.md",
            self.root / "26_Sensitive",
            self.root / "31_Business" / "Other People Reference.md",
            self.root / "Actual Documents" / "Identity",
        ]
        for root in roots:
            with self.subTest(root=root):
                with self.assertRaises(publisher.Refusal):
                    publisher.validate_target(root, publisher.corpus_target(root))

    def test_pin_mismatch_refuses(self):
        pin = self.root / "pin.json"
        result = run_cli(self.source, self.vault, "--write-pin", str(pin))
        self.assertEqual(result.returncode, 0, result.stderr)
        write(self.source / "Notes" / "alpha.md", b"changed")
        result = run_cli(self.source, self.vault, "--pin", str(pin))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PIN_MISMATCH", result.stdout)
        self.assertFalse(self.vault.exists())

    def test_target_outside_corpus_folder_refuses(self):
        import publish_social_corpus as publisher

        vault = self.root / "vault"
        with self.assertRaises(publisher.Refusal):
            publisher.validate_target(vault, vault / "other")

    def test_source_under_excluded_vault_path_refuses_before_reading(self):
        import publish_social_corpus as publisher

        excluded_source = self.vault / "AI Reference" / "source"
        with self.assertRaises(publisher.Refusal):
            publisher.publish(excluded_source, self.vault)

    def test_script_contains_no_file_deletion_calls(self):
        text = SCRIPT.read_text(encoding="utf-8")
        for token in ("os.remove", ".unlink(", "rmtree(", "shutil.move"):
            self.assertNotIn(token, text)

    def test_report_contains_actions_and_geo_hashes(self):
        report = self.root / "report.json"
        result = run_cli(self.source, self.vault, "--report", str(report))
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(report.read_text(encoding="utf-8"))
        self.assertIn("actions", data)
        self.assertIn("geo_sha256_before", data)
        self.assertIn("refusals", data)


if __name__ == "__main__":
    unittest.main()
