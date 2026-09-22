import unittest

import build_social_publication as builder


class PublicationGateTests(unittest.TestCase):
    def test_gate_refuses_when_confirmed_member_has_no_judgement(self):
        confirmed = [{"stable_id": "post-a"}, {"stable_id": "post-b"}]
        judgements = [{"stable_id": "post-a"}]

        with self.assertRaisesRegex(RuntimeError, "missing judgement"):
            builder.validate_judgement_coverage(confirmed, judgements)


if __name__ == "__main__":
    unittest.main()
