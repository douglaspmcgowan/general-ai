import json
import tempfile
import unittest
from pathlib import Path

import check_social_rendering as checker


class RenderingGateTests(unittest.TestCase):
    def test_valid_tree_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Notes").mkdir()
            (root / "Notes" / "note.md").write_text("# Note\n", encoding="utf-8")
            (root / "index.md").write_text("[[50 Knowledge/57 Corpus/Saved AI Posts/Notes/note.md|Note]]\n", encoding="utf-8")
            (root / "Saved AI Posts.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "a", "type": "file", "x": 0, "y": 0, "width": 420, "height": 300, "file": "50 Knowledge/57 Corpus/Saved AI Posts/Notes/note.md"},
                ],
                "edges": [],
            }), encoding="utf-8")
            violations, counts = checker.check_tree(root)
            self.assertEqual(violations, [])
            self.assertEqual(counts["canvases"], 1)

    def test_catches_relative_canvas_path_and_split_table_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Notes").mkdir()
            (root / "Notes" / "note.md").write_text("# Note\n", encoding="utf-8")
            (root / "bad.md").write_text(
                "| Entity | Kind |\n| --- | --- |\n| [[Notes/note.md|Note]] | tool |\n",
                encoding="utf-8",
            )
            (root / "bad.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "a", "type": "file", "x": 0, "y": 0, "width": 420, "height": 300, "file": "Notes/note.md"},
                ],
                "edges": [],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertTrue(any("unescaped pipe" in item for item in violations))
            self.assertTrue(any("not vault-root relative" in item for item in violations))


if __name__ == "__main__":
    unittest.main()
