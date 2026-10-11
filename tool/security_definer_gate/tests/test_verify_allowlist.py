import sys
import hashlib
import unittest
from copy import deepcopy
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_allowlist import GateFailure, _has_positive_nullsafe_guard as _guard, verify  # noqa: E402


SIGNATURE = "public.example(p_id uuid)"
PROSRC = "BEGIN IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) THEN RAISE EXCEPTION 'denied'; END IF; END;"
FUNCTIONDEF = "CREATE FUNCTION public.example(p_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$" + PROSRC + "$body$;"
HASH = hashlib.md5(FUNCTIONDEF.encode("utf-8")).hexdigest()


def manifest_row():
    return {
        "signature": SIGNATURE,
        "md5_functiondef": HASH,
        "owner": "postgres",
        "database": "postgres",
        "language": "plpgsql",
        "search_path": ['search_path=""'],
        "execute": {"anon": False, "authenticated": True, "agent_ro": False, "service_role": False},
        "execute_acl": [],
        "effective_execute_roles": ["postgres", "authenticated"],
        "classification": "ROLE_POSITIVE_TEMPLATE",
        "reviewer": "security-reviewer",
        "reviewed_at": "2026-10-11",
    }


def fixture():
    approved = manifest_row()
    current = deepcopy({key: approved[key] for key in (
        "signature", "md5_functiondef", "owner", "search_path", "execute", "execute_acl", "effective_execute_roles", "language"
    )})
    current.update({"schema": "public", "security_definer": True, "prosrc": PROSRC, "function_definition": FUNCTIONDEF})
    return (
        {
            "metadata": {
                "project_ref": "project-test",
                "database": "postgres",
                "approval_state": "APPROVED_ALLOWLIST",
                "function_count": 1,
                "event_trigger_count": 1,
            },
            "functions": [approved],
            "event_triggers": [{
                "name": "ensure_rls",
                "event": "ddl_command_end",
                "enabled": "O",
                "tags": ["CREATE TABLE", "CREATE TABLE AS", "SELECT INTO"],
                "signature": "public.example_trigger()",
            }],
        },
        {
            "metadata": {"project_ref": "project-test", "database": "postgres"},
            "functions": [current],
            "event_triggers": [{
                "name": "ensure_rls",
                "event": "ddl_command_end",
                "enabled": "O",
                "tags": ["CREATE TABLE", "CREATE TABLE AS", "SELECT INTO"],
                "signature": "public.example_trigger()",
            }],
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
        observed["functions"][0]["md5_functiondef"] = "f" * 32
        with self.assertRaisesRegex(GateFailure, "md5_functiondef changed"):
            verify(manifest, observed, "project-test")

    def test_matching_hash_with_unsafe_first_statement_fails_guard_scan(self):
        manifest, observed = fixture()
        unsafe = "BEGIN UPDATE public.example SET value = true; END;"
        observed["functions"][0]["prosrc"] = unsafe
        altered_definition = FUNCTIONDEF.replace(PROSRC, unsafe)
        digest = hashlib.md5(altered_definition.encode("utf-8")).hexdigest()
        manifest["functions"][0]["md5_functiondef"] = digest
        observed["functions"][0]["md5_functiondef"] = digest
        observed["functions"][0]["function_definition"] = altered_definition
        with self.assertRaisesRegex(GateFailure, "first executable statement"):
            verify(manifest, observed, "project-test")

    def test_catalog_functiondef_must_match_its_exported_hash(self):
        manifest, observed = fixture()
        observed["functions"][0]["function_definition"] = "CREATE FUNCTION changed() RETURNS void AS $$SELECT 1$$ LANGUAGE sql"
        with self.assertRaisesRegex(GateFailure, "function_definition does not match catalog md5_functiondef"):
            verify(manifest, observed, "project-test")

    def test_no_guard_helper_still_requires_catalog_body(self):
        manifest, observed = fixture()
        manifest["functions"][0]["classification"] = "NO_GUARD_HELPER"
        manifest["functions"][0]["justification"] = "Pure helper with no authorization boundary."
        observed["functions"][0].pop("prosrc")
        with self.assertRaisesRegex(GateFailure, "catalog prosrc must not be empty"):
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

    def test_event_trigger_attachment_must_match_reviewed_inventory(self):
        manifest, observed = fixture()
        observed["event_triggers"][0]["enabled"] = "D"
        with self.assertRaisesRegex(GateFailure, "event trigger ensure_rls: enabled differs"):
            verify(manifest, observed, "project-test")

    def test_unapproved_event_trigger_fails_closed(self):
        manifest, observed = fixture()
        observed["event_triggers"].append({
            "name": "unexpected",
            "event": "sql_drop",
            "enabled": "O",
            "tags": None,
            "signature": "public.other()",
        })
        with self.assertRaisesRegex(GateFailure, "unapproved catalog event trigger"):
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

    def test_language_drift_fails_closed(self):
        manifest, observed = fixture()
        observed["functions"][0]["language"] = "sql"
        observed["functions"][0]["function_definition"] = FUNCTIONDEF.replace("plpgsql", "sql")
        observed["functions"][0]["md5_functiondef"] = hashlib.md5(observed["functions"][0]["function_definition"].encode()).hexdigest()
        with self.assertRaisesRegex(GateFailure, "language differs"):
            verify(manifest, observed, "project-test")

    def test_empty_prosrc_fails_closed_even_with_functiondef_hash(self):
        manifest, observed = fixture()
        observed["functions"][0]["prosrc"] = ""
        with self.assertRaisesRegex(GateFailure, "prosrc must not be empty"):
            verify(manifest, observed, "project-test")

    def test_no_guard_helper_cannot_read_role_or_jwt(self):
        manifest, observed = fixture()
        manifest["functions"][0]["classification"] = "NO_GUARD_HELPER"
        manifest["functions"][0]["justification"] = "Pure helper."
        observed["functions"][0]["prosrc"] = "BEGIN RETURN public.app_role(); END;"
        with self.assertRaisesRegex(GateFailure, "may not inspect role or JWT identity"):
            verify(manifest, observed, "project-test")

    def test_no_guard_helper_cannot_read_quoted_identity_function(self):
        manifest, observed = fixture()
        manifest["functions"][0]["classification"] = "NO_GUARD_HELPER"
        manifest["functions"][0]["justification"] = "Pure helper."
        observed["functions"][0]["prosrc"] = 'BEGIN RETURN auth."jwt"(); END;'
        with self.assertRaisesRegex(GateFailure, "may not inspect role or JWT identity"):
            verify(manifest, observed, "project-test")

    def test_no_guard_helper_cannot_use_dynamic_sql(self):
        manifest, observed = fixture()
        manifest["functions"][0]["classification"] = "NO_GUARD_HELPER"
        manifest["functions"][0]["justification"] = "Pure helper."
        observed["functions"][0]["prosrc"] = "BEGIN EXECUTE 'SELECT auth.jwt()'; END;"
        with self.assertRaisesRegex(GateFailure, "use dynamic SQL"):
            verify(manifest, observed, "project-test")

    def test_no_guard_helper_cannot_read_auth_role_or_sql_identity(self):
        for identity_read in (
            "auth.role()",
            "CURRENT_USER",
            "SESSION_USER",
            "CURRENT_ROLE",
        ):
            with self.subTest(identity_read=identity_read):
                manifest, observed = fixture()
                manifest["functions"][0]["classification"] = "NO_GUARD_HELPER"
                manifest["functions"][0]["justification"] = "Pure helper."
                observed["functions"][0]["prosrc"] = f"BEGIN RETURN {identity_read}; END;"
                with self.assertRaisesRegex(GateFailure, "may not inspect role or JWT identity"):
                    verify(manifest, observed, "project-test")

    def test_only_allowlisted_functions_can_be_pinned_exceptions(self):
        manifest, observed = fixture()
        exception_signature = "public.ressources_du_groupe(p_groupe_id uuid)"
        manifest["functions"][0].update({
            "signature": exception_signature,
            "classification": "PINNED_FUNCTIONDEF_EXCEPTION",
            "justification": "Reviewed immutable exception.",
        })
        observed["functions"][0]["signature"] = exception_signature
        verify(manifest, observed, "project-test")

    def test_owner_must_be_postgres(self):
        manifest, observed = fixture()
        manifest["functions"][0]["owner"] = "authenticated"
        observed["functions"][0]["owner"] = "authenticated"
        with self.assertRaisesRegex(GateFailure, "owner must be postgres"):
            verify(manifest, observed, "project-test")

    def test_exception_handler_bypass_fails_guard_scan(self):
        body = PROSRC.replace("END IF; END;", "END IF; EXCEPTION WHEN others THEN NULL; END;")
        self.assertFalse(_guard(body))

    def test_public_acl_fails_closed(self):
        manifest, observed = fixture()
        acl = {"grantee": "PUBLIC", "grantor": "postgres", "privilege": "EXECUTE", "is_grantable": False}
        manifest["functions"][0]["execute_acl"] = [acl]
        observed["functions"][0]["execute_acl"] = [acl]
        with self.assertRaisesRegex(GateFailure, "PUBLIC/anon/agent_ro/service_role execute privilege is forbidden"):
            verify(manifest, observed, "project-test")

    def test_service_role_effective_execution_fails_closed(self):
        manifest, observed = fixture()
        manifest["functions"][0]["execute"]["service_role"] = True
        observed["functions"][0]["execute"]["service_role"] = True
        manifest["functions"][0]["effective_execute_roles"].append("service_role")
        observed["functions"][0]["effective_execute_roles"].append("service_role")
        with self.assertRaisesRegex(GateFailure, "effective PUBLIC/anon/agent_ro/service_role execution is forbidden"):
            verify(manifest, observed, "project-test")

    def test_non_allowlisted_exception_signature_fails_closed(self):
        manifest, observed = fixture()
        manifest["functions"][0]["classification"] = "PINNED_FUNCTIONDEF_EXCEPTION"
        manifest["functions"][0]["justification"] = "reviewed"
        with self.assertRaisesRegex(GateFailure, "signature is not an approved pinned exception"):
            verify(manifest, observed, "project-test")

    def test_database_mismatch_fails_closed(self):
        manifest, observed = fixture()
        observed["metadata"]["database"] = "other"
        with self.assertRaisesRegex(GateFailure, "database does not match"):
            verify(manifest, observed, "project-test")

    def test_non_iso_review_date_fails_closed(self):
        manifest, observed = fixture()
        manifest["functions"][0]["reviewed_at"] = "20261011"
        with self.assertRaisesRegex(GateFailure, "reviewed_at is required"):
            verify(manifest, observed, "project-test")


if __name__ == "__main__":
    unittest.main()
