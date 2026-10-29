#!/usr/bin/env python3
"""Validate terraform/repos/*.yaml against repos.schema.json (Phase 1 item 1
of the tf-github improvement plan, 2026-10-29).

Enforces the full set of legal top-level keys in the config-as-code surface
so a misspelled key (e.g. `aws_acount`) fails the PR loudly instead of
silently defaulting away via the `try(..., default)` pattern used throughout
repositories.tf and github-oidc-roles.tf.

`repos/_defaults.yaml` is the profile layer (Phase 1 item 2), not a repo
config, and is validated against the separate repos_defaults.schema.json.

Usage:
    validate_repos_schema.py [--repos-dir terraform/repos]

Exit status: 0 if every file validates, 1 otherwise (with every failure
printed, not just the first).
"""

from __future__ import annotations

import argparse
import pathlib
import sys

import yaml
from jsonschema import Draft7Validator, RefResolver

DEFAULTS_FILE = "_defaults.yaml"


def load_schema(path: pathlib.Path) -> dict:
    import json

    return json.loads(path.read_text())


def make_validator(schema_path: pathlib.Path, store_dir: pathlib.Path) -> Draft7Validator:
    schema = load_schema(schema_path)
    # Local $ref resolution (repos_defaults.schema.json references
    # repos.schema.json#/$defs/repoFields by relative filename) needs a
    # base_uri rooted at the directory holding both schema files.
    resolver = RefResolver(base_uri=store_dir.as_uri() + "/", referrer=schema)
    return Draft7Validator(schema, resolver=resolver)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--repos-dir",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parent / "repos",
    )
    args = ap.parse_args()

    schema_dir = args.repos_dir.parent
    repo_schema_path = schema_dir / "repos.schema.json"
    defaults_schema_path = schema_dir / "repos_defaults.schema.json"

    if not repo_schema_path.exists() or not defaults_schema_path.exists():
        print(f"error: schema files not found in {schema_dir}", file=sys.stderr)
        return 2

    repo_validator = make_validator(repo_schema_path, schema_dir)
    defaults_validator = make_validator(defaults_schema_path, schema_dir)

    yaml_files = sorted(args.repos_dir.glob("*.yaml"))
    if not yaml_files:
        print(f"error: no *.yaml files found in {args.repos_dir}", file=sys.stderr)
        return 2

    error_count = 0
    checked = 0
    for path in yaml_files:
        with path.open() as fh:
            data = yaml.safe_load(fh)

        validator = defaults_validator if path.name == DEFAULTS_FILE else repo_validator
        errors = sorted(validator.iter_errors(data), key=lambda e: list(e.path))
        checked += 1
        if not errors:
            continue
        error_count += len(errors)
        print(f"FAIL {path}")
        for err in errors:
            loc = ".".join(str(p) for p in err.path) or "<root>"
            print(f"      {loc}: {err.message}")

    # Cross-check: every `profile:` value used by a repo must exist in
    # _defaults.yaml's profiles map (the schema's enum only catches drift
    # against the schema file itself, not against _defaults.yaml going stale).
    defaults_path = args.repos_dir / DEFAULTS_FILE
    with defaults_path.open() as fh:
        known_profiles = set(yaml.safe_load(fh).get("profiles", {}))
    for path in yaml_files:
        if path.name == DEFAULTS_FILE:
            continue
        with path.open() as fh:
            data = yaml.safe_load(fh) or {}
        profile = data.get("profile")
        if profile is not None and profile not in known_profiles:
            error_count += 1
            print(f"FAIL {path}\n      profile: {profile!r} is not defined in {DEFAULTS_FILE}")

    if error_count:
        print(f"\n{error_count} error(s) across {checked} file(s)", file=sys.stderr)
        return 1

    print(f"OK: {checked} file(s) in {args.repos_dir} validate against schema")
    return 0


if __name__ == "__main__":
    sys.exit(main())
