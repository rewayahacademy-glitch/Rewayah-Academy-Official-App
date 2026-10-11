import sys
import hashlib
import unittest
from copy import deepcopy
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_allowlist import GateFailure, verify  # noqa: E402


SIGNATURE = "public.example(p_id uuid)"
PROSRC = "BEGIN IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) THEN RAISE EXCEPTION 'denied'; END IF; END;"
HASH = hashlib.md5(PROSRC.encode("utf-8")).hexdigest()


def manifest_row():
    return {
        "signature": SIGNATURE,
        "md5_prosrc": HASH,
        "owner": "postgres",
        "search_path": ['search_path=""'],
        "execute": {"anon": False, "authenticated": True, "agent_ro": False},
        "classification": "ROLE_POSITIVE_TEMPLATE",
        "reviewer": "security-reviewer",
        "reviewed_at": "2026-10-11",
    }


def fixture():
    approved = manifest_row()
    current = deepcopy({key: approved[key] for key in (
        "signature", "md5_prosrc", "owner", "search_path", "execute"
    )})
    current.update({"schema": "public", "security_definer": True, "prosrc": PROSRC})
    return (
        {
            "metadata": {
                "project_ref": "project-test",
                "approval_state": "APPROVED_ALLOWLIST",
                "function_count": 1,
            },
            "functions": [approved],
        },
        {
            "metadata": {"project_ref": "project-test", "database": "postgres"},
            "functions": [current],
            "trigger_functions": [
                {"signature": "public.example_trigger()", "security_definer": False}
            ],
        },
    )


class VerifyAllowlistTests(unittest.TestCase):
    def test_matching_reviewed_manifest_passes(self):
        manifest, observed = fixture()
        verify(manifest, observed, "project-test")

    def test_unreviewed_inventory_fails_closed(self):
        manifest, observed = fixture()
        manifest["metadata"]["approval_state"] = "INVENTORY_ONLY_NOT_ALLOWLIST"
        with self.assertRaisesRegex(GateFailure, "not marked APPROVED_ALLOWLIST"):
            verify(manifest, observed, "project-test")

    def test_new_signature_fails_closed(self):
        manifest, observed = fixture()
        observed["functions"].append(dict(observed["functions"][0], signature="public.other()"))
        with self.assertRaisesRegex(GateFailure, "unapproved catalog signature"):
            verify(manifest, observed, "project-test")

    def test_changed_body_hash_fails_closed(self):
        manifest, observed = fixture()
        observed["functions"][0]["md5_prosrc"] = "f" * 32
        with self.assertRaisesRegex(GateFailure, "md5_prosrc changed"):
            verify(manifest, observed, "project-test")

    def test_matching_hash_with_unsafe_first_statement_fails_guard_scan(self):
        manifest, observed = fixture()
        unsafe = "BEGIN UPDATE public.example SET value = true; END;"
        digest = hashlib.md5(unsafe.encode("utf-8")).hexdigest()
        manifest["functions"][0]["md5_prosrc"] = digest
        observed["functions"][0]["md5_prosrc"] = digest
        observed["functions"][0]["prosrc"] = unsafe
        with self.assertRaisesRegex(GateFailure, "first executable statement"):
            verify(manifest, observed, "project-test")

    def test_catalog_prosrc_must_match_its_exported_hash(self):
        manifest, observed = fixture()
        observed["functions"][0]["prosrc"] = "BEGIN PERFORM 1; END;"
        with self.assertRaisesRegex(GateFailure, "prosrc does not match catalog md5_prosrc"):
            verify(manifest, observed, "project-test")

    def test_no_guard_helper_still_requires_catalog_body(self):
        manifest, observed = fixture()
        manifest["functions"][0]["classification"] = "NO_GUARD_HELPER"
        manifest["functions"][0]["justification"] = "Pure helper with no authorization boundary."
        observed["functions"][0].pop("prosrc")
        with self.assertRaisesRegex(GateFailure, "catalog prosrc and md5_prosrc are required"):
            verify(manifest, observed, "project-test")

    def test_non_definer_catalog_row_fails_closed(self):
        manifest, observed = fixture()
        observed["functions"][0]["security_definer"] = False
        with self.assertRaisesRegex(GateFailure, "not SECURITY DEFINER"):
            verify(manifest, observed, "project-test")

    def test_trigger_definer_fails_closed(self):
        manifest, observed = fixture()
        observed["trigger_functions"][0]["security_definer"] = True
        with self.assertRaisesRegex(GateFailure, "trigger function is SECURITY DEFINER"):
            verify(manifest, observed, "project-test")

    def test_wrong_catalog_project_fails_closed(self):
        manifest, observed = fixture()
        observed["metadata"]["project_ref"] = "another-project"
        with self.assertRaisesRegex(GateFailure, "catalog project_ref"):
            verify(manifest, observed, "project-test")

    def test_changed_effective_grant_fails_closed(self):
        manifest, observed = fixture()
        observed["functions"][0]["execute"]["anon"] = True
        with self.assertRaisesRegex(GateFailure, "execute differs"):
            verify(manifest, observed, "project-test")

    def test_nonempty_search_path_fails_closed(self):
        manifest, observed = fixture()
        manifest["functions"][0]["search_path"].append("search_path=public")
        observed["functions"][0]["search_path"].append("search_path=public")
        with self.assertRaisesRegex(GateFailure, "search_path must be exactly empty"):
            verify(manifest, observed, "project-test")

    def test_missing_no_guard_justification_fails_closed(self):
        manifest, observed = fixture()
        manifest["functions"][0]["classification"] = "NO_GUARD_HELPER"
        with self.assertRaisesRegex(GateFailure, "requires a justification"):
            verify(manifest, observed, "project-test")

    def test_non_iso_review_date_fails_closed(self):
        manifest, observed = fixture()
        manifest["functions"][0]["reviewed_at"] = "20261011"
        with self.assertRaisesRegex(GateFailure, "reviewed_at is required"):
            verify(manifest, observed, "project-test")


if __name__ == "__main__":
    unittest.main()
