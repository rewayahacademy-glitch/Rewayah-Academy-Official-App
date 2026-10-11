#!/usr/bin/env python3
"""Fail-closed comparison of a reviewed SECURITY DEFINER manifest and catalog export."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any

_MD5 = re.compile(r"^[0-9a-f]{32}$")
_ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_CLASSIFICATIONS = {
    "ROLE_POSITIVE_TEMPLATE",
    "NO_GUARD_HELPER",
    "PINNED_FUNCTIONDEF_EXCEPTION",
}
_ROLES = {"anon", "authenticated", "agent_ro", "service_role"}
_PINNED_EXCEPTION_SIGNATURES = {
    "public.etat_presence(p_session_id uuid, p_profile_id uuid)",
    "public.ressources_du_groupe(p_groupe_id uuid)",
    "public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer)",
}
_ACCOUNT_VALID = ["PUBLIC", ".", "APP_ACCOUNT_VALID", "(", ")"]
_APP_ROLE = ["PUBLIC", ".", "APP_ROLE", "(", ")"]


class GateFailure(ValueError):
    """The inventory is incomplete or differs from the observed catalog."""


def _sql_tokens(source: str) -> list[str]:
    """Tokenize enough PL/pgSQL to recognize one exact first-statement guard.

    Comments and quoted strings are opaque tokens, so guard-looking text inside
    either cannot satisfy the check. Unsupported syntax is retained as tokens
    and therefore fails the exact template match.
    """
    tokens: list[str] = []
    index = 0
    while index < len(source):
        char = source[index]
        if char.isspace():
            index += 1
            continue
        if source.startswith("--", index):
            newline = source.find("\n", index + 2)
            index = len(source) if newline < 0 else newline + 1
            continue
        if source.startswith("/*", index):
            depth = 1
            index += 2
            while index < len(source) and depth:
                if source.startswith("/*", index):
                    depth += 1
                    index += 2
                elif source.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            if depth:
                return ["<UNTERMINATED_COMMENT>"]
            continue
        if char in "Ee" and source.startswith("'", index + 1):
            index += 2
            literal: list[str] = []
            while index < len(source):
                if source[index] == "\\" and index + 1 < len(source):
                    literal.append(source[index + 1])
                    index += 2
                    continue
                if source[index] == "'":
                    if index + 1 < len(source) and source[index + 1] == "'":
                        literal.append("'")
                        index += 2
                        continue
                    index += 1
                    break
                literal.append(source[index])
                index += 1
            else:
                return ["<UNTERMINATED_ESCAPE_STRING>"]
            tokens.append("<STRING:" + "".join(literal) + ">")
            continue
        if char == "'":
            index += 1
            literal: list[str] = []
            while index < len(source):
                if source[index] == "\\":
                    # Ordinary string backslash semantics depend on the
                    # function's creation-time setting. Refuse to guess.
                    return ["<UNSUPPORTED_BACKSLASH_STRING>"]
                if source[index] == "'":
                    if index + 1 < len(source) and source[index + 1] == "'":
                        literal.append("'")
                        index += 2
                        continue
                    index += 1
                    break
                literal.append(source[index])
                index += 1
            else:
                return ["<UNTERMINATED_STRING>"]
            tokens.append("<STRING:" + "".join(literal) + ">")
            continue
        if char == '"':
            index += 1
            identifier: list[str] = []
            while index < len(source):
                if source[index] == '"':
                    if index + 1 < len(source) and source[index + 1] == '"':
                        identifier.append('"')
                        index += 2
                        continue
                    index += 1
                    break
                identifier.append(source[index])
                index += 1
            else:
                return ["<UNTERMINATED_IDENTIFIER>"]
            tokens.append("<QUOTED_IDENTIFIER:" + "".join(identifier) + ">")
            continue
        if char == "$":
            delimiter = re.match(r"\$[A-Za-z_][A-Za-z_0-9]*\$|\$\$", source[index:])
            if delimiter:
                tag = delimiter.group(0)
                end = source.find(tag, index + len(tag))
                if end < 0:
                    return ["<UNTERMINATED_DOLLAR_STRING>"]
                tokens.append("<STRING:" + source[index + len(tag):end] + ">")
                index = end + len(tag)
                continue
        if char.isalpha() or char == "_":
            end = index + 1
            while end < len(source) and (source[end].isalnum() or source[end] in "_$"):
                end += 1
            tokens.append(source[index:end].upper())
            index = end
            continue
        if source.startswith(("::", "<=", ">=", "<>", "!=", ":=", "=>"), index):
            tokens.append(source[index:index + 2])
            index += 2
            continue
        tokens.append(char)
        index += 1
    return tokens


def _matching_paren(tokens: list[str], opening: int) -> int | None:
    depth = 0
    for index in range(opening, len(tokens)):
        if tokens[index] == "(":
            depth += 1
        elif tokens[index] == ")":
            depth -= 1
            if depth == 0:
                return index
    return None


def _is_role_check(tokens: list[str]) -> bool:
    def role_expression(value: list[str]) -> bool:
        prefix = _APP_ROLE
        if value[:len(prefix)] != prefix:
            return False
        tail = value[len(prefix):]
        if len(tail) == 2 and tail[0] == "=" and tail[1].startswith("<STRING:"):
            return bool(tail[1][8:-1].strip())
        if len(tail) < 4 or tail[:2] != ["IN", "("] or tail[-1] != ")":
            return False
        choices = tail[2:-1]
        if not choices or len(choices) % 2 == 0:
            return False
        return all(
            (position % 2 == 0 and token.startswith("<STRING:") and bool(token[8:-1].strip()))
            or (position % 2 == 1 and token == ",")
            for position, token in enumerate(choices)
        )

    # Compare the whole expression by splitting only at its top-level AND.
    depth = 0
    for index, token in enumerate(tokens):
        if token == "(":
            depth += 1
        elif token == ")":
            depth -= 1
        elif token == "AND" and depth == 0:
            left, right = tokens[:index], tokens[index + 1:]
            return (left == _ACCOUNT_VALID and role_expression(right)) or (
                right == _ACCOUNT_VALID and role_expression(left)
            )
    return False


def _has_positive_nullsafe_guard(prosrc: str) -> bool:
    """Return true only for the approved, null-safe first PL/pgSQL guard."""
    if not isinstance(prosrc, str) or not prosrc:
        return False
    tokens = _sql_tokens(prosrc)
    if any(tokens[index:index + 2] == ["EXCEPTION", "WHEN"] for index in range(len(tokens) - 1)):
        return False
    try:
        body_start = tokens.index("BEGIN") + 1
    except ValueError:
        return False
    if tokens[body_start:body_start + 4] != ["IF", "NOT", "COALESCE", "("]:
        return False
    close = _matching_paren(tokens, body_start + 3)
    if close is None:
        return False
    inner = tokens[body_start + 4:close]
    depth = 0
    separator: int | None = None
    for index, token in enumerate(inner):
        if token == "(":
            depth += 1
        elif token == ")":
            depth -= 1
        elif token == "," and depth == 0:
            if separator is not None:
                return False
            separator = index
    if separator is None or inner[separator + 1:] != ["FALSE"]:
        return False
    if not _is_role_check(inner[:separator]):
        return False
    if tokens[close + 1:close + 3] != ["THEN", "RAISE"]:
        return False
    if close + 3 >= len(tokens) or tokens[close + 3] != "EXCEPTION":
        return False
    end_raise = next((i for i in range(close + 4, len(tokens)) if tokens[i] == ";"), None)
    return end_raise is not None and tokens[end_raise + 1:end_raise + 4] == ["END", "IF", ";"]


def _no_guard_helper_reads_identity(prosrc: str) -> bool:
    """Reject identity access even through quoted names or dynamic SQL."""
    tokens = _sql_tokens(prosrc)
    forbidden = {
        "APP_ROLE", "ROLE", "JWT", "UID", "CLAIMS", "CURRENT_SETTING",
        "CURRENT_USER", "SESSION_USER", "CURRENT_ROLE", "SESSION_ROLE",
    }
    for index, token in enumerate(tokens):
        if token in forbidden or token == "EXECUTE":
            return True
        # auth.* is the Supabase identity/JWT namespace. Reject the namespace
        # as a whole so new identity helpers cannot silently bypass this rule.
        if token == "AUTH" and tokens[index + 1:index + 2] == ["."]:
            return True
        prefix = "<QUOTED_IDENTIFIER:"
        if token.startswith(prefix) and token.endswith(">"):
            if token[len(prefix):-1].upper() in forbidden:
                return True
    return False


def _load(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise GateFailure(f"cannot read JSON {path}: {error}") from error
    if not isinstance(value, dict):
        raise GateFailure(f"{path}: top level must be an object")
    return value


def _load_catalog_argument(argument: str) -> dict[str, Any]:
    if argument != "-":
        return _load(Path(argument))
    try:
        value = json.load(sys.stdin)
    except json.JSONDecodeError as error:
        raise GateFailure(f"cannot read catalog JSON from stdin: {error}") from error
    if not isinstance(value, dict):
        raise GateFailure("catalog stdin: top level must be an object")
    return value


def _rows(document: dict[str, Any], field: str, source: str) -> dict[str, dict[str, Any]]:
    values = document.get(field)
    if not isinstance(values, list):
        raise GateFailure(f"{source}: {field} must be a list")
    result: dict[str, dict[str, Any]] = {}
    for row in values:
        if not isinstance(row, dict):
            raise GateFailure(f"{source}: {field} contains a non-object row")
        signature = row.get("signature")
        if not isinstance(signature, str) or not signature:
            raise GateFailure(f"{source}: {field} row has no signature")
        if signature in result:
            raise GateFailure(f"{source}: duplicate signature {signature}")
        result[signature] = row
    return result


def _named_rows(document: dict[str, Any], field: str, source: str) -> dict[str, dict[str, Any]]:
    values = document.get(field)
    if not isinstance(values, list):
        raise GateFailure(f"{source}: {field} must be a list")
    result: dict[str, dict[str, Any]] = {}
    for row in values:
        if not isinstance(row, dict):
            raise GateFailure(f"{source}: {field} contains a non-object row")
        name = row.get("name")
        if not isinstance(name, str) or not name:
            raise GateFailure(f"{source}: {field} row has no name")
        if name in result:
            raise GateFailure(f"{source}: duplicate name {name}")
        result[name] = row
    return result


def _check_review(row: dict[str, Any], signature: str) -> None:
    classification = row.get("classification")
    if not isinstance(classification, str) or classification not in _CLASSIFICATIONS:
        raise GateFailure(f"{signature}: unrecognized or missing classification")
    if not isinstance(row.get("reviewer"), str) or not row["reviewer"].strip():
        raise GateFailure(f"{signature}: reviewer is required")
    reviewed_at = row.get("reviewed_at")
    if not isinstance(reviewed_at, str) or not _ISO_DATE.fullmatch(reviewed_at):
        raise GateFailure(f"{signature}: reviewed_at is required")
    try:
        date.fromisoformat(reviewed_at)
    except ValueError as error:
        raise GateFailure(f"{signature}: reviewed_at must be YYYY-MM-DD") from error
    if classification == "NO_GUARD_HELPER" and not (
        isinstance(row.get("justification"), str) and row["justification"].strip()
    ):
        raise GateFailure(f"{signature}: NO_GUARD_HELPER requires a justification")
    if classification == "PINNED_FUNCTIONDEF_EXCEPTION" and not (
        isinstance(row.get("justification"), str) and row["justification"].strip()
    ):
        raise GateFailure(f"{signature}: pinned exception requires a justification")
    if classification == "PINNED_FUNCTIONDEF_EXCEPTION" and signature not in _PINNED_EXCEPTION_SIGNATURES:
        raise GateFailure(f"{signature}: signature is not an approved pinned exception")
    if signature in _PINNED_EXCEPTION_SIGNATURES and classification != "PINNED_FUNCTIONDEF_EXCEPTION":
        raise GateFailure(f"{signature}: pinned exception classification is required")
    if row.get("owner") != "postgres":
        raise GateFailure(f"{signature}: owner must be postgres")
    if row.get("language") not in {"plpgsql", "sql"}:
        raise GateFailure(f"{signature}: language must be explicitly reviewed as plpgsql or sql")
    if not isinstance(row.get("execute_acl"), list):
        raise GateFailure(f"{signature}: explicit execute_acl manifest is required")
    forbidden_grantees = {"PUBLIC", "anon", "agent_ro", "service_role"}
    if any(not isinstance(acl, dict) or acl.get("grantee") in forbidden_grantees for acl in row["execute_acl"]):
        raise GateFailure(f"{signature}: PUBLIC/anon/agent_ro/service_role execute privilege is forbidden")
    if not isinstance(row.get("effective_execute_roles"), list):
        raise GateFailure(f"{signature}: effective_execute_roles must be a list")
    if forbidden_grantees.intersection(row["effective_execute_roles"]):
        raise GateFailure(f"{signature}: effective PUBLIC/anon/agent_ro/service_role execution is forbidden")


def verify(manifest: dict[str, Any], observed: dict[str, Any], project_ref: str) -> None:
    metadata = manifest.get("metadata")
    if not isinstance(metadata, dict):
        raise GateFailure("manifest metadata is required")
    if metadata.get("project_ref") != project_ref:
        raise GateFailure("manifest project_ref does not match --project-ref")
    observed_metadata = observed.get("metadata")
    if not isinstance(observed_metadata, dict) or observed_metadata.get("project_ref") != project_ref:
        raise GateFailure("catalog project_ref does not match --project-ref")
    database = metadata.get("database")
    if not isinstance(database, str) or not database.strip():
        raise GateFailure("manifest database is required")
    if observed_metadata.get("database") != database:
        raise GateFailure("catalog database does not match the reviewed manifest")
    if metadata.get("approval_state") != "APPROVED_ALLOWLIST":
        raise GateFailure("manifest is not marked APPROVED_ALLOWLIST")

    expected = _rows(manifest, "functions", "manifest")
    actual = _rows(observed, "functions", "catalog")
    if metadata.get("function_count") != len(expected):
        raise GateFailure("manifest function_count does not match its rows")

    expected_event_triggers = _named_rows(manifest, "event_triggers", "manifest")
    actual_event_triggers = _named_rows(observed, "event_triggers", "catalog")
    if metadata.get("event_trigger_count") != len(expected_event_triggers):
        raise GateFailure("manifest event_trigger_count does not match its rows")

    problems: list[str] = []
    for signature in sorted(expected.keys() - actual.keys()):
        problems.append(f"missing catalog signature: {signature}")
    for signature in sorted(actual.keys() - expected.keys()):
        problems.append(f"unapproved catalog signature: {signature}")

    for signature in sorted(expected.keys() & actual.keys()):
        approved = expected[signature]
        current = actual[signature]
        if current.get("security_definer") is not True:
            problems.append(f"{signature}: catalog row is not SECURITY DEFINER")
        try:
            _check_review(approved, signature)
        except GateFailure as error:
            problems.append(str(error))
        if approved.get("classification") == "ROLE_POSITIVE_TEMPLATE" and not _has_positive_nullsafe_guard(
            current.get("prosrc")
        ):
            problems.append(
                f"{signature}: first executable statement is not an approved positive null-safe role guard"
            )
        function_definition = current.get("function_definition")
        language = current.get("language")
        prosrc = current.get("prosrc")
        if not isinstance(prosrc, str) or not prosrc.strip():
            problems.append(f"{signature}: catalog prosrc must not be empty")
        if language != approved.get("language"):
            problems.append(f"{signature}: language differs from the reviewed manifest")
        catalog_digest = current.get("md5_functiondef")
        if not isinstance(function_definition, str) or not function_definition.strip() or not isinstance(catalog_digest, str) or not _MD5.fullmatch(catalog_digest):
            problems.append(f"{signature}: catalog function_definition and md5_functiondef are required")
        else:
            computed_digest = hashlib.md5(function_definition.encode("utf-8")).hexdigest()
            if computed_digest != catalog_digest:
                problems.append(f"{signature}: function_definition does not match catalog md5_functiondef")
        if not isinstance(language, str) or not language.strip():
            problems.append(f"{signature}: catalog language is required")
        digest = approved.get("md5_functiondef")
        if not isinstance(digest, str) or not _MD5.fullmatch(digest):
            problems.append(f"{signature}: invalid approved md5_functiondef")
        elif current.get("md5_functiondef") != digest:
            problems.append(f"{signature}: md5_functiondef changed")
        if approved.get("classification") == "NO_GUARD_HELPER":
            if isinstance(prosrc, str) and _no_guard_helper_reads_identity(prosrc):
                problems.append(
                    f"{signature}: NO_GUARD_HELPER may not inspect role or JWT identity or use dynamic SQL"
                )
        for field in ("owner", "search_path", "execute", "execute_acl", "effective_execute_roles"):
            if current.get(field) != approved.get(field):
                problems.append(f"{signature}: {field} differs from the reviewed manifest")
        search_path = approved.get("search_path")
        if search_path != ['search_path=""']:
            problems.append(f"{signature}: search_path must be exactly empty")
        execute = approved.get("execute")
        if (
            not isinstance(execute, dict)
            or set(execute) != _ROLES
            or any(not isinstance(value, bool) for value in execute.values())
        ):
            problems.append(f"{signature}: execute ACL must cover anon/authenticated/agent_ro")

    for name in sorted(expected_event_triggers.keys() - actual_event_triggers.keys()):
        problems.append(f"missing catalog event trigger: {name}")
    for name in sorted(actual_event_triggers.keys() - expected_event_triggers.keys()):
        problems.append(f"unapproved catalog event trigger: {name}")
    for name in sorted(expected_event_triggers.keys() & actual_event_triggers.keys()):
        approved = expected_event_triggers[name]
        current = actual_event_triggers[name]
        for field in ("event", "enabled", "tags", "signature"):
            if current.get(field) != approved.get(field):
                problems.append(f"event trigger {name}: {field} differs from the reviewed manifest")

    triggers = observed.get("trigger_functions")
    if not isinstance(triggers, list):
        problems.append("catalog trigger_functions list is required")
    else:
        for trigger in triggers:
            if not isinstance(trigger, dict) or not isinstance(trigger.get("signature"), str):
                problems.append("catalog contains a malformed trigger function row")
            elif trigger.get("security_definer") is not False:
                problems.append(f"trigger function is SECURITY DEFINER: {trigger['signature']}")

    if problems:
        raise GateFailure("\n".join(problems))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--catalog", required=True, help="catalog JSON file, or - to read from stdin")
    parser.add_argument("--project-ref", required=True)
    args = parser.parse_args(argv)
    try:
        verify(_load(args.manifest), _load_catalog_argument(args.catalog), args.project_ref)
    except GateFailure as error:
        print(f"SECURITY DEFINER gate: FAIL\n{error}", file=sys.stderr)
        return 1
    print("SECURITY DEFINER gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
