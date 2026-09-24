import unittest

import build_social_entities as entity_builder
import build_social_publication as builder


class PublicationGateTests(unittest.TestCase):
    def test_gate_refuses_when_confirmed_member_has_no_judgement(self):
        confirmed = [{"stable_id": "post-a"}, {"stable_id": "post-b"}]
        judgements = [{"stable_id": "post-a"}]

        with self.assertRaisesRegex(RuntimeError, "missing judgement"):
            builder.validate_judgement_coverage(confirmed, judgements)

    def test_coverage_rejects_unexplained_slide_gap(self):
        rows = builder.coverage_rows(
            [{"stable_id": "post-a", "caption": "caption"}],
            {"post-a": {"sc": "post-a", "images_expected": 2, "images_read": 1, "slides": []}},
            {},
        )
        self.assertEqual(rows[0]["gap"], "slides read 1 of 2")
        with self.assertRaisesRegex(RuntimeError, "post-a"):
            builder.validate_coverage_rows(rows)

    def test_coverage_accepts_complete_post_without_audio(self):
        rows = builder.coverage_rows(
            [{"stable_id": "post-a", "caption": "caption"}],
            {"post-a": {"sc": "post-a", "images_expected": 1, "images_read": 1, "slides": [{"n": 1, "text": "text"}]}},
            {},
        )
        self.assertEqual(rows[0]["gap"], "")
        self.assertEqual(builder.validate_coverage_rows(rows), {"rows": 1, "gaps": 0})

    def test_media_resource_objects_use_public_name_without_stringifying_dict(self):
        detail = builder.media_details(
            "post-a",
            {"post-a": {"sc": "post-a", "images_expected": 1, "images_read": 1, "slides": [{"n": 1, "text": "x", "resources": [{"type": "prompt", "name": "/hdreal"}, None]}]}},
            {},
        )
        self.assertEqual(detail["resources"], ["/hdreal"])
        self.assertNotIn("type", " ".join(detail["resources"]))


class EntityAdmissionTests(unittest.TestCase):
    def test_media_entity_normalization_rejects_incidental_names(self):
        self.assertIsNone(entity_builder.normalize_entity_name("@lostandlucky"))
        self.assertEqual(entity_builder.normalize_entity_name("- Three.js -"), "Three.js")
        self.assertIsNone(entity_builder.normalize_entity_name("https://example.com/tool"))
        self.assertIsNone(entity_builder.normalize_entity_name("order.svg"))
        self.assertIsNone(entity_builder.normalize_entity_name("---"))

    def test_media_entity_normalization_merges_case_and_possessive_aliases(self):
        self.assertEqual(entity_builder.entity_key("claude code"), entity_builder.entity_key("Claude Code"))
        self.assertEqual(entity_builder.entity_key("Anthropic's"), entity_builder.entity_key("Anthropic"))


if __name__ == "__main__":
    unittest.main()
