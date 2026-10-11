import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_allowlist import _has_positive_nullsafe_guard  # noqa: E402


class PositiveGuardScannerTests(unittest.TestCase):
    def test_accepts_canonical_role_list_guard_before_any_write(self):
        body = """
        BEGIN
          IF NOT COALESCE(
            public.app_account_valid() AND public.app_role() IN ('admin', 'teacher'),
            false
          ) THEN
            RAISE EXCEPTION 'not allowed';
          END IF;
          UPDATE public.example SET value = true;
        END;
        """
        self.assertTrue(_has_positive_nullsafe_guard(body))

    def test_accepts_role_equality_and_reversed_conjunction(self):
        body = """
        BEGIN
          IF NOT COALESCE(public.app_role() = 'admin' AND public.app_account_valid(), false)
          THEN RAISE EXCEPTION 'not allowed'; END IF;
        END;
        """
        self.assertTrue(_has_positive_nullsafe_guard(body))

    def test_ignores_guard_text_in_comments_and_literals(self):
        body = """
        BEGIN
          -- IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false)
          IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false)
          THEN RAISE EXCEPTION 'not allowed'; END IF;
          PERFORM 'IF NOT COALESCE(public.app_account_valid() AND public.app_role() = ''admin'', false)';
        END;
        """
        self.assertTrue(_has_positive_nullsafe_guard(body))

    def test_rejects_guard_after_an_executable_statement(self):
        body = """
        BEGIN
          UPDATE public.example SET value = true;
          IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false)
          THEN RAISE EXCEPTION 'not allowed'; END IF;
        END;
        """
        self.assertFalse(_has_positive_nullsafe_guard(body))

    def test_rejects_null_or_true_fallback(self):
        for fallback in ("NULL", "true"):
            with self.subTest(fallback=fallback):
                body = f"""
                BEGIN
                  IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', {fallback})
                  THEN RAISE EXCEPTION 'not allowed'; END IF;
                END;
                """
                self.assertFalse(_has_positive_nullsafe_guard(body))

    def test_rejects_guard_in_a_nested_or_dead_branch(self):
        body = """
        BEGIN
          IF true THEN
            IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false)
            THEN RAISE EXCEPTION 'not allowed'; END IF;
          END IF;
        END;
        """
        self.assertFalse(_has_positive_nullsafe_guard(body))

    def test_rejects_negative_or_incomplete_role_checks(self):
        unsafe_bodies = (
            "IF public.app_role() <> 'admin' OR NOT public.app_account_valid() THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE(public.app_role() = 'admin', false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', true) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) THEN PERFORM 1; END IF;",
        )
        for statement in unsafe_bodies:
            with self.subTest(statement=statement):
                self.assertFalse(_has_positive_nullsafe_guard(f"BEGIN {statement} END;"))

    def test_rejects_known_guard_bypass_shapes(self):
        unsafe_bodies = (
            # A nested fallback can turn a missing role claim into access.
            "IF NOT COALESCE(COALESCE(public.app_role() = 'admin', true) AND public.app_account_valid(), false) THEN RAISE EXCEPTION 'x'; END IF;",
            # The following rewrites let a missing or unauthorized role through.
            "IF NOT (public.app_account_valid() AND public.app_role() = 'admin') THEN RAISE EXCEPTION 'x'; END IF;",
            "IF (public.app_role() = 'admin') <> true THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT (COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS DISTINCT FROM true) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE(public.app_role() = 'admin' AND public.app_account_valid() = false, false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE((public.app_account_valid()) IS FALSE AND public.app_role() = 'admin', false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF skip_check AND NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE(public.app_account_valid() AND public.app_role()::text <> 'admin', false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE(public.app_account_valid() AND public.app_role() <> ALL(ARRAY['guest']), false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT GREATEST(COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false), true) THEN RAISE EXCEPTION 'x'; END IF;",
        )
        for statement in unsafe_bodies:
            with self.subTest(statement=statement):
                self.assertFalse(_has_positive_nullsafe_guard(f"BEGIN {statement} END;"))

    def test_rejects_unrecognized_role_expressions_fail_closed(self):
        unrecognized_bodies = (
            # These forms are stricter or may be equivalent, but are not a reviewed template.
            "IF NOT COALESCE(public.app_account_valid() AND lower(public.app_role()) = 'admin', false) THEN RAISE EXCEPTION 'x'; END IF;",
            "IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin' AND public.fake_app_account_valid(), false) THEN RAISE EXCEPTION 'x'; END IF;",
            # A case statement or dynamic query is not the first-statement guard.
            "CASE WHEN COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) THEN NULL; ELSE NULL; END CASE;",
            "EXECUTE 'SELECT NOT COALESCE(public.app_account_valid() AND public.app_role() = ''admin'', false)';",
        )
        for statement in unrecognized_bodies:
            with self.subTest(statement=statement):
                self.assertFalse(_has_positive_nullsafe_guard(f"BEGIN {statement} END;"))

    def test_rejects_textual_guard_inside_a_string_only(self):
        body = """
        BEGIN
          PERFORM 'IF NOT COALESCE(public.app_account_valid() AND public.app_role() = ''admin'', false) THEN RAISE EXCEPTION ''x''; END IF;';
        END;
        """
        self.assertFalse(_has_positive_nullsafe_guard(body))

    def test_does_not_treat_guard_text_in_escape_string_as_the_body(self):
        body = r"""
        DECLARE fake text := E'fake \' BEGIN IF NOT COALESCE(public.app_account_valid() AND public.app_role() = \'admin\', false) THEN RAISE EXCEPTION \'x\'; END IF;';
        BEGIN
          PERFORM 1;
        END;
        """
        self.assertFalse(_has_positive_nullsafe_guard(body))

    def test_ignores_nested_block_comments(self):
        body = """
        BEGIN
          /* outer /* IF NOT COALESCE(fake) THEN */ comment */
          IF NOT COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false)
          THEN RAISE EXCEPTION 'not allowed'; END IF;
        END;
        """
        self.assertTrue(_has_positive_nullsafe_guard(body))


if __name__ == "__main__":
    unittest.main()
