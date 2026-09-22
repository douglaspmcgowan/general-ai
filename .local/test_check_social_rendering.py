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

    def test_catches_detail_canvas_entity_without_category_post(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            publication = root / "publication-dryrun"
            entities_dir = publication / "Entities"
            canvases_dir = publication / "Canvases"
            entities_dir.mkdir(parents=True)
            canvases_dir.mkdir()
            (entities_dir / "Allowed.md").write_text("# Allowed\n", encoding="utf-8")
            (entities_dir / "Other.md").write_text("# Other\n", encoding="utf-8")
            (root / "classification").mkdir()
            (root / "classification" / "entities-v1.json").write_text(json.dumps({
                "entities": [
                    {"canonical": "Allowed", "pointers": [{"source": "collection", "stable_id": "p1"}]},
                    {"canonical": "Other", "pointers": [{"source": "collection", "stable_id": "p2"}]},
                ]
            }), encoding="utf-8")
            (root / "classification" / "primary-topics-v2.json").write_text(json.dumps([
                {"stable_id": "p1", "primary_topic": "ai-news"},
                {"stable_id": "p2", "primary_topic": "design-tools"},
            ]), encoding="utf-8")
            (canvases_dir / "AI news.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "g", "type": "group", "x": 0, "y": 0, "width": 400, "height": 300, "label": "Other entities"},
                    {"id": "n", "type": "text", "x": 60, "y": 60, "width": 260, "height": 90,
                     "text": "[[50 Knowledge/57 Corpus/Saved AI Posts/Entities/Other.md|Other]]"},
                ],
                "edges": [],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(publication)
            self.assertTrue(any("does not belong to category ai-news" in item for item in violations))

    def test_catches_group_aspect_and_height_limits(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "narrow.canvas").write_text(json.dumps({
                "nodes": [{"id": "g", "type": "group", "x": 0, "y": 0, "width": 100, "height": 2500, "label": "Tall"}],
                "edges": [],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertTrue(any("aspect ratio" in item for item in violations))
            self.assertTrue(any("height" in item and "2400" in item for item in violations))


if __name__ == "__main__":
    unittest.main()
