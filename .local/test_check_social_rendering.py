import json
import tempfile
import unittest
from pathlib import Path

import check_social_rendering as checker


class RenderingGateTests(unittest.TestCase):
    def test_source_note_permalink_body_link_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            notes = root / "Notes"
            notes.mkdir()
            frontmatter = "---\ntype: thing\nsubtype: source\npermalink: \"https://www.instagram.com/p/abc123/\"\n---\n"
            note = notes / "note.md"
            note.write_text(frontmatter + "\n# Note\n\n[Open on Instagram](https://www.instagram.com/p/abc123/)\n", encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertFalse(any("permalink" in item for item in violations))

            note.write_text(frontmatter + "\n# Note\n", encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertTrue(any("permalink" in item and "missing from the body" in item for item in violations))

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

    def test_card_lines_gate_checks_limits_prefixes_and_source_substrings(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            publication = root / "publication-dryrun"
            publication.mkdir()
            classification = root / "classification" / "comparisons"
            classification.mkdir(parents=True)
            (classification / "ai-news.json").write_text(json.dumps({
                "headline": "A source summary",
                "clusters": [{"summary": {"text": "A source summary"}, "comparison": []}],
            }), encoding="utf-8")
            (root / "classification" / "card-lines-v1.json").write_text(json.dumps({
                "categories": {"ai-news": {"line": "A source summary"}},
                "clusters": {"ai-news": {"x": {"line": "one two three four five six seven eight nine ten eleven twelve thirteen"}}},
                "relations": [],
            }), encoding="utf-8")
            violations = checker._card_lines_violations(publication)
            self.assertTrue(any("exceeds 12 words" in item for item in violations))
            self.assertTrue(any("source-summary substring" in item for item in violations))

    def test_catches_bad_edge_endpoint_and_label(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bad.canvas").write_text(json.dumps({
                "nodes": [{"id": "a", "type": "text", "x": 0, "y": 0, "width": 200, "height": 60, "text": "# A"}],
                "edges": [{"id": "e", "fromNode": "a", "toNode": "missing", "label": ""}],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertTrue(any("missing endpoint" in item for item in violations))
            self.assertTrue(any("unlabeled edge" in item for item in violations))

    def test_requires_summary_first_group_child_and_heading_first_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bad.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "g", "type": "group", "x": 0, "y": 0, "width": 500, "height": 300, "label": "Group"},
                    {"id": "n", "type": "text", "x": 20, "y": 20, "width": 220, "height": 80, "text": "bare line"},
                ],
                "edges": [],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertTrue(any("first line is not a heading" in item for item in violations))
            self.assertTrue(any("top-most child is not a summary" in item for item in violations))

    def test_catches_canvas_bounding_box(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Saved AI Posts.canvas").write_text(json.dumps({
                "nodes": [{"id": "a", "type": "text", "x": 0, "y": 0, "width": 2601, "height": 1801, "text": "# A"}],
                "edges": [],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertTrue(any("bounding box" in item for item in violations))

    def test_catches_sibling_overlap(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bad.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "a", "type": "text", "x": 0, "y": 0, "width": 220, "height": 80, "text": "# A"},
                    {"id": "b", "type": "text", "x": 100, "y": 20, "width": 220, "height": 80, "text": "# B"},
                ],
                "edges": [],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(root)
            self.assertTrue(any("sibling nodes overlap" in item for item in violations))

    def test_top_edge_requires_two_non_ubiquitous_shared_entities(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            publication = root / "publication-dryrun"
            publication.mkdir()
            classification = root / "classification"
            classification.mkdir()
            (classification / "entities-v1.json").write_text(json.dumps({"entities": [
                {"canonical": "Only one", "pointers": [{"source": "collection", "stable_id": "p1"}]},
            ]}), encoding="utf-8")
            (classification / "primary-topics-v2.json").write_text(json.dumps([
                {"stable_id": "p1", "primary_topic": "ai-news"},
                {"stable_id": "p2", "primary_topic": "business"},
            ]), encoding="utf-8")
            (publication / "Saved AI Posts.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "a", "type": "text", "x": 0, "y": 0, "width": 400, "height": 180, "text": "## AI news"},
                    {"id": "b", "type": "text", "x": 500, "y": 0, "width": 400, "height": 180, "text": "## Business"},
                ],
                "edges": [{"id": "e", "fromNode": "a", "toNode": "b", "label": "1 shared: Only one"}],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(publication)
            self.assertTrue(any("lacks two non-ubiquitous shared entities" in item for item in violations))

    def test_top_edge_rejects_ubiquitous_only_overlap(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            publication = root / "publication-dryrun"
            publication.mkdir()
            classification = root / "classification"
            classification.mkdir()
            pointers = [{"source": "collection", "stable_id": f"p{i}"} for i in range(1, 6)]
            (classification / "entities-v1.json").write_text(json.dumps({"entities": [{"canonical": "Everywhere", "pointers": pointers}]}), encoding="utf-8")
            (classification / "primary-topics-v2.json").write_text(json.dumps([
                {"stable_id": "p1", "primary_topic": "ai-news"},
                {"stable_id": "p2", "primary_topic": "business"},
                {"stable_id": "p3", "primary_topic": "design-tools"},
                {"stable_id": "p4", "primary_topic": "research"},
                {"stable_id": "p5", "primary_topic": "security"},
            ]), encoding="utf-8")
            (publication / "Saved AI Posts.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "a", "type": "text", "x": 0, "y": 0, "width": 400, "height": 180, "text": "## AI news"},
                    {"id": "b", "type": "text", "x": 500, "y": 0, "width": 400, "height": 180, "text": "## Business"},
                ],
                "edges": [{"id": "e", "fromNode": "a", "toNode": "b", "fromSide": "right", "toSide": "left", "label": "shared: Everywhere"}],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(publication)
            self.assertTrue(any("non-ubiquitous" in item for item in violations))

    def test_detail_cluster_edges_require_hand_written_lines(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            publication = root / "publication-dryrun"
            canvases = publication / "Canvases"
            canvases.mkdir(parents=True)
            (canvases / "AI news.canvas").write_text(json.dumps({
                "nodes": [
                    {"id": "g1", "type": "group", "x": 0, "y": 0, "width": 500, "height": 300, "label": "One"},
                    {"id": "g2", "type": "group", "x": 700, "y": 0, "width": 500, "height": 300, "label": "Two"},
                    {"id": "s1", "type": "text", "x": 20, "y": 20, "width": 440, "height": 100, "text": "## One"},
                    {"id": "s2", "type": "text", "x": 720, "y": 20, "width": 440, "height": 100, "text": "## Two"},
                ],
                "edges": [{"id": "e", "fromNode": "g1", "toNode": "g2", "fromSide": "right", "toSide": "left", "label": "shared: data"}],
            }), encoding="utf-8")
            violations, _counts = checker.check_tree(publication)
            self.assertTrue(any("cluster-to-cluster edge" in item for item in violations))

    def test_edge_crossing_counter_uses_declared_sides(self):
        rects = {
            "a": (0, 0, 100, 100), "b": (300, 300, 400, 400),
            "c": (300, 0, 400, 100), "d": (0, 300, 100, 400),
        }
        edges = [
            {"fromNode": "a", "toNode": "b", "fromSide": "right", "toSide": "left"},
            {"fromNode": "c", "toNode": "d", "fromSide": "left", "toSide": "right"},
        ]
        self.assertEqual(checker._edge_crossings(edges, rects), 1)


if __name__ == "__main__":
    unittest.main()
