#!/usr/bin/env python3
"""Fail-closed comparison of a reviewed SECURITY DEFINER manifest and catalog export."""

from __future__ import annotations

import argparse
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
}
_ROLES = {"anon", "authenticated", "agent_ro"}


class GateFailure(ValueError):
    """The inventory is incomplete or differs from the observed catalog."""


def _load(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise GateFailure(f"cannot read JSON {path}: {error}") from error
    if not isinstance(value, dict):
        raise GateFailure(f"{path}: top level must be an object")
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


def verify(manifest: dict[str, Any], observed: dict[str, Any], project_ref: str) -> None:
    metadata = manifest.get("metadata")
    if not isinstance(metadata, dict):
        raise GateFailure("manifest metadata is required")
    if metadata.get("project_ref") != project_ref:
        raise GateFailure("manifest project_ref does not match --project-ref")
    observed_metadata = observed.get("metadata")
    if not isinstance(observed_metadata, dict) or observed_metadata.get("project_ref") != project_ref:
        raise GateFailure("catalog project_ref does not match --project-ref")
    if metadata.get("approval_state") != "APPROVED_ALLOWLIST":
        raise GateFailure("manifest is not marked APPROVED_ALLOWLIST")

    expected = _rows(manifest, "functions", "manifest")
    actual = _rows(observed, "functions", "catalog")
    if metadata.get("function_count") != len(expected):
        raise GateFailure("manifest function_count does not match its rows")

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
        digest = approved.get("md5_prosrc")
        if not isinstance(digest, str) or not _MD5.fullmatch(digest):
            problems.append(f"{signature}: invalid approved md5_prosrc")
        elif current.get("md5_prosrc") != digest:
            problems.append(f"{signature}: md5_prosrc changed")
        for field in ("owner", "search_path", "execute"):
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
    parser.add_argument("--catalog", required=True, type=Path)
    parser.add_argument("--project-ref", required=True)
    args = parser.parse_args(argv)
    try:
        verify(_load(args.manifest), _load(args.catalog), args.project_ref)
    except GateFailure as error:
        print(f"SECURITY DEFINER gate: FAIL\n{error}", file=sys.stderr)
        return 1
    print("SECURITY DEFINER gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
