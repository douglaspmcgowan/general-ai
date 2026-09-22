#!/usr/bin/env python3
"""Copy the reviewed saved-post publication tree into its one allowed vault folder.

The publisher is deliberately small and standard-library-only.  It never deletes a
vault file and refuses unsafe destinations before it lists or reads them.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


CORPUS_SUFFIX = Path("50 Knowledge") / "57 Corpus" / "Saved AI Posts"
EXCLUDED_DIRS = ("Backups", "_review", "_evidence")
EXCLUDED_FILES = (
    "run-manifest.json",
    "CONTRACT-EVIDENCE.md",
    "Continuation plan and progress map.md",
)
GEO_RELATIVE = Path("Notes") / "geo_grandmasters — AI surveillance and commercial power — DZ7sxpHyfzu.md"
PIN_METHOD = "sha256(sorted relative-path\\0sha256\\0size\\n)"
CANVAS_DEFAULT_EDGE_ENDS = {"fromEnd": "none", "toEnd": "arrow"}


class Refusal(RuntimeError):
    """A run-level refusal that must prevent all vault writes."""


def _run_rendering_gate(source: Path) -> None:
    checker = Path(__file__).with_name("check_social_rendering.py")
    if not checker.is_file():
        raise Refusal(f"rendering check unavailable: {checker}")
    result = subprocess.run(
        [sys.executable, str(checker), str(source)],
        cwd=str(checker.parent),
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    summary = next((line for line in result.stdout.splitlines() if line.startswith("CANVASES=")), "rendering checker produced no summary")
    if result.returncode:
        raise Refusal(f"rendering check failed: {summary}")
    print("RENDERING_CHECK=" + summary)


def _lexical(path: os.PathLike[str] | str) -> str:
    """Normalize a path without touching the filesystem."""

    return os.path.normcase(os.path.normpath(os.path.abspath(os.fspath(path))))


def _under(path: os.PathLike[str] | str, ancestor: os.PathLike[str] | str) -> bool:
    child = _lexical(path)
    parent = _lexical(ancestor)
    return child == parent or child.startswith(parent + os.sep)


def _contains_actual_identity(path: os.PathLike[str] | str) -> bool:
    parts = [part.casefold() for part in Path(_lexical(path)).parts]
    for index in range(len(parts) - 2):
        if parts[index] == "actual documents" and parts[index + 1] == "identity":
            return True
    return False


def corpus_target(vault_root: os.PathLike[str] | str) -> Path:
    return Path(vault_root) / CORPUS_SUFFIX


def _forbidden_reason(vault_root: Path, candidate: Path) -> str | None:
    if _contains_actual_identity(candidate):
        return "path contains Actual Documents/Identity"
    forbidden = [
        (vault_root / "AI Reference", "vault-root AI Reference"),
        (vault_root / "40_Reference" / "AI Reference.md", "40_Reference/AI Reference.md"),
        (vault_root / "26_Sensitive", "vault-root 26_Sensitive"),
        (vault_root / "31_Business" / "Other People Reference.md", "31_Business/Other People Reference.md"),
    ]
    root_parts = [part.casefold() for part in Path(_lexical(vault_root)).parts]
    if root_parts and root_parts[-1] in {"ai reference", "26_sensitive"}:
        forbidden.append((vault_root, "vault root is excluded"))
    if len(root_parts) >= 2 and tuple(root_parts[-2:]) in {
        ("40_reference", "ai reference.md"),
        ("31_business", "other people reference.md"),
    }:
        forbidden.append((vault_root, "vault root is excluded"))
    for path, label in forbidden:
        if _under(candidate, path):
            return label
    return None


def validate_target(vault_root: os.PathLike[str] | str, target: os.PathLike[str] | str) -> Path:
    """Validate the only permitted target before any target filesystem operation."""

    root = Path(vault_root)
    expected = corpus_target(root)
    if _lexical(target) != _lexical(expected):
        raise Refusal(f"target outside corpus folder: {target}")
    reason = _forbidden_reason(root, Path(target))
    if reason:
        raise Refusal(f"excluded vault path ({reason}): {target}")
    return Path(target)


def _source_files(source: Path, *, copy_set: bool) -> tuple[dict[str, bytes], list[str]]:
    if not source.is_dir():
        raise Refusal(f"source is missing or not a directory: {source}")
    files: dict[str, bytes] = {}
    for directory, dirnames, filenames in os.walk(source):
        dirnames[:] = sorted(name for name in dirnames if name not in EXCLUDED_DIRS)
        relative_directory = Path(directory).relative_to(source)
        for filename in sorted(filenames):
            relative = (relative_directory / filename).as_posix()
            if copy_set and filename in EXCLUDED_FILES:
                continue
            files[relative] = (Path(directory) / filename).read_bytes()
    return files, list(EXCLUDED_DIRS) + list(EXCLUDED_FILES)


def _sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def _default_canvas_sides(edge: dict, nodes: dict[str, dict]) -> tuple[str, str] | None:
    """Return the sides Obsidian chooses from the relative node positions."""

    source = nodes.get(edge.get("fromNode"))
    target = nodes.get(edge.get("toNode"))
    if not isinstance(source, dict) or not isinstance(target, dict):
        return None
    try:
        source_center = (float(source["x"]) + float(source["width"]) / 2, float(source["y"]) + float(source["height"]) / 2)
        target_center = (float(target["x"]) + float(target["width"]) / 2, float(target["y"]) + float(target["height"]) / 2)
    except (KeyError, TypeError, ValueError):
        return None
    dx = target_center[0] - source_center[0]
    dy = target_center[1] - source_center[1]
    if dx == 0 and dy == 0:
        return None
    if abs(dx) >= abs(dy):
        return ("right", "left") if dx > 0 else ("left", "right")
    return ("bottom", "top") if dy > 0 else ("top", "bottom")


def _canonical_canvas(value: object) -> bytes | None:
    if not isinstance(value, dict):
        return None
    canvas = dict(value)
    nodes = canvas.get("nodes")
    edges = canvas.get("edges")
    if not isinstance(nodes, list) or not isinstance(edges, list):
        return None
    canonical_nodes = [dict(node) if isinstance(node, dict) else node for node in nodes]
    node_map = {node.get("id"): node for node in canonical_nodes if isinstance(node, dict) and isinstance(node.get("id"), str)}
    canonical_edges: list[object] = []
    for edge in edges:
        if not isinstance(edge, dict):
            canonical_edges.append(edge)
            continue
        normalized = dict(edge)
        for field, default in CANVAS_DEFAULT_EDGE_ENDS.items():
            if normalized.get(field) == default:
                normalized.pop(field, None)
        default_sides = _default_canvas_sides(normalized, node_map)
        if default_sides is not None and (normalized.get("fromSide"), normalized.get("toSide")) == default_sides:
            normalized.pop("fromSide", None)
            normalized.pop("toSide", None)
        canonical_edges.append(normalized)
    canvas["nodes"] = sorted(canonical_nodes, key=lambda item: str(item.get("id", "")) if isinstance(item, dict) else "")
    canvas["edges"] = sorted(canonical_edges, key=lambda item: str(item.get("id", "")) if isinstance(item, dict) else "")
    try:
        return json.dumps(canvas, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    except (TypeError, ValueError):
        return None


def _canonical_json(content: bytes) -> bytes | None:
    try:
        value = json.loads(content.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None
    return _canonical_canvas(value)


def _canonical_json_value(content: bytes) -> bytes | None:
    try:
        value = json.loads(content.decode("utf-8"))
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    except (UnicodeDecodeError, json.JSONDecodeError, TypeError, ValueError):
        return None


def _yaml_scalar(value: str) -> object:
    value = value.strip()
    if not value:
        return None
    if value in {"~", "null", "Null", "NULL"}:
        return None
    if value.casefold() in {"true", "false"}:
        return value.casefold() == "true"
    if value.startswith('"') and value.endswith('"'):
        return json.loads(value)
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1].replace("''", "'")
    if value.startswith(("[", "{")):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            pass
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value


def _yaml_commentless(value: str) -> str:
    quoted: str | None = None
    escaped = False
    for index, char in enumerate(value):
        if quoted == '"' and char == "\\" and not escaped:
            escaped = True
            continue
        if char in {'"', "'"} and not escaped:
            quoted = None if quoted == char else (char if quoted is None else quoted)
        if char == "#" and quoted is None and (index == 0 or value[index - 1].isspace()):
            return value[:index].rstrip()
        escaped = False
    return value.rstrip()


def _yaml_key_value(value: str) -> tuple[str, str | None] | None:
    quoted: str | None = None
    escaped = False
    for index, char in enumerate(value):
        if quoted == '"' and char == "\\" and not escaped:
            escaped = True
            continue
        if char in {'"', "'"} and not escaped:
            quoted = None if quoted == char else (char if quoted is None else quoted)
        if char == ":" and quoted is None and (index + 1 == len(value) or value[index + 1].isspace()):
            key = value[:index].strip()
            if not key:
                return None
            if len(key) >= 2 and key[0] == key[-1] and key[0] in {'"', "'"}:
                key = str(_yaml_scalar(key))
            return key, value[index + 1 :].strip() or None
        escaped = False
    return None


def _canonical_yaml(content: bytes) -> bytes | None:
    try:
        text = content.decode("utf-8")
    except UnicodeDecodeError:
        return None
    rows: list[tuple[int, str]] = []
    for raw in text.splitlines():
        if "\t" in raw[: len(raw) - len(raw.lstrip())]:
            return None
        stripped = _yaml_commentless(raw).strip()
        if not stripped:
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        rows.append((indent, stripped))
    if not rows:
        return None

    def parse_block(position: int, indent: int) -> tuple[object, int]:
        if position >= len(rows) or rows[position][0] < indent:
            return {}, position
        sequence = rows[position][1] == "-" or rows[position][1].startswith("- ")
        if sequence:
            result: list[object] = []
            while position < len(rows) and rows[position][0] == indent and (rows[position][1] == "-" or rows[position][1].startswith("- ")):
                item = rows[position][1][1:].strip()
                position += 1
                if not item:
                    value, position = parse_block(position, rows[position][0] if position < len(rows) and rows[position][0] > indent else indent + 1)
                    result.append(value)
                    continue
                pair = _yaml_key_value(item)
                if pair is None:
                    result.append(_yaml_scalar(item))
                    continue
                key, raw_value = pair
                mapping: dict[str, object] = {key: _yaml_scalar(raw_value) if raw_value is not None else None}
                if raw_value is None and position < len(rows) and rows[position][0] > indent:
                    nested, position = parse_block(position, rows[position][0])
                    mapping[key] = nested
                if position < len(rows) and rows[position][0] > indent:
                    extra, position = parse_block(position, rows[position][0])
                    if not isinstance(extra, dict):
                        raise ValueError("sequence mapping continuation must be a map")
                    mapping.update(extra)
                result.append(mapping)
            return result, position
        result_map: dict[str, object] = {}
        while position < len(rows) and rows[position][0] == indent and not rows[position][1].startswith("- ") and rows[position][1] != "-":
            pair = _yaml_key_value(rows[position][1])
            if pair is None:
                raise ValueError("invalid YAML mapping")
            key, raw_value = pair
            if key in result_map:
                raise ValueError("duplicate YAML key")
            position += 1
            if raw_value is None and position < len(rows) and rows[position][0] > indent:
                value, position = parse_block(position, rows[position][0])
            else:
                value = _yaml_scalar(raw_value)
            result_map[key] = value
        return result_map, position

    try:
        value, position = parse_block(0, rows[0][0])
        if position != len(rows):
            return None
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    except (TypeError, ValueError, json.JSONDecodeError):
        return None


def _canonical_content(relative: str, content: bytes) -> str | None:
    if relative.casefold().endswith(".canvas"):
        canonical = _canonical_json(content)
    elif relative.casefold().endswith(".base"):
        canonical = _canonical_json_value(content) or _canonical_yaml(content)
    else:
        canonical = None
    return _sha256(canonical) if canonical is not None else None


def _pin_tree_hash(entries: dict[str, bytes]) -> str:
    digest = hashlib.sha256()
    for relative in sorted(entries):
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(_sha256(entries[relative]).encode("ascii"))
        digest.update(b"\0")
        digest.update(str(len(entries[relative])).encode("ascii"))
        digest.update(b"\n")
    return digest.hexdigest()


def _pin_payload(entries: dict[str, bytes]) -> dict:
    return {
        "pinned_utc": datetime.now(timezone.utc).date().isoformat(),
        "reviewed_by": None,
        "scope": "source excluding Backups, _review, _evidence",
        "file_count": len(entries),
        "tree_method": PIN_METHOD,
        "tree_sha256": _pin_tree_hash(entries),
        "files": {
            relative: {
                "sha256": _sha256(entries[relative]),
                "size": len(entries[relative]),
                **({"canonical_sha256": canonical} if (canonical := _canonical_content(relative, entries[relative])) else {}),
            }
            for relative in sorted(entries)
        },
    }


def _pin_mismatch(entries: dict[str, bytes], pin: dict) -> tuple[list[str], list[str], list[str], bool]:
    expected = pin.get("files")
    if not isinstance(expected, dict):
        raise Refusal("pin has no files map")
    actual_names = set(entries)
    expected_names = set(expected)
    added = sorted(actual_names - expected_names)
    missing = sorted(expected_names - actual_names)
    changed = sorted(
        relative
        for relative in actual_names & expected_names
        if not isinstance(expected[relative], dict)
        or expected[relative].get("sha256") != _sha256(entries[relative])
        or expected[relative].get("size") != len(entries[relative])
    )
    aggregate = _pin_tree_hash(entries) == pin.get("tree_sha256")
    return changed, added, missing, aggregate


def _frontmatter_flags(content: bytes) -> tuple[str | None, bool]:
    try:
        text = content.decode("utf-8")
    except UnicodeDecodeError:
        return None, False
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, False
    try:
        end = next(index for index, line in enumerate(lines[1:], 1) if line.strip() == "---")
    except StopIteration:
        return None, False
    authored_by: str | None = None
    locked = False
    for line in lines[1:end]:
        match = re.match(r"^\s*authored_by\s*:\s*['\"]?([^'\"]+?)['\"]?\s*$", line)
        if match:
            authored_by = match.group(1).strip()
        match = re.match(r"^\s*locked\s*:\s*(true|false)\s*$", line, re.IGNORECASE)
        if match:
            locked = match.group(1).casefold() == "true"
    return authored_by, locked


def _geo_hash(path: Path) -> str:
    if not path.is_file():
        return "MISSING"
    return _sha256(path.read_bytes())


def _atomic_write(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    with os.fdopen(descriptor, "wb") as handle:
        handle.write(content)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary_name, path)


def _target_files(target: Path) -> dict[str, bytes]:
    if not target.is_dir():
        return {}
    found: dict[str, bytes] = {}
    for directory, dirnames, filenames in os.walk(target):
        dirnames.sort()
        for filename in sorted(filenames):
            path = Path(directory) / filename
            found[path.relative_to(target).as_posix()] = path.read_bytes()
    return found


def _print_exclusions() -> None:
    for name in EXCLUDED_DIRS:
        print(f"EXCLUDED_DIR={name}/")
    for name in EXCLUDED_FILES:
        print(f"EXCLUDED_FILE={name}")


def publish(
    source: os.PathLike[str] | str,
    vault_root: os.PathLike[str] | str,
    *,
    apply: bool = False,
    pin: os.PathLike[str] | str | None = None,
    backup_root: os.PathLike[str] | str | None = None,
    report: os.PathLike[str] | str | None = None,
    write_pin: os.PathLike[str] | str | None = None,
    owned_pin: os.PathLike[str] | str | None = None,
) -> dict:
    source_path = Path(source)
    root_path = Path(vault_root)
    target = validate_target(root_path, corpus_target(root_path))
    backup_path = Path(backup_root) if backup_root is not None else source_path.parent / "vault-backups"
    guarded_paths = (
        (source_path, "source"),
        (backup_path, "backup-root"),
        (Path(pin), "pin") if pin is not None else None,
        (Path(write_pin), "write-pin") if write_pin is not None else None,
        (Path(owned_pin), "owned-pin") if owned_pin is not None else None,
        (Path(report), "report") if report is not None else None,
    )
    for guarded in guarded_paths:
        if guarded is None:
            continue
        guarded_path, label = guarded
        reason = _forbidden_reason(root_path, guarded_path)
        if reason:
            raise Refusal(f"{label} falls under excluded vault path ({reason}): {guarded_path}")
    if _under(backup_path, root_path):
        raise Refusal(f"backup-root is inside vault: {backup_path}")
    owned_entries: dict[str, dict] = {}
    if owned_pin is not None:
        owned_files = json.loads(Path(owned_pin).read_text(encoding="utf-8")).get("files", {})
        owned_entries = {
            relative: entry
            for relative, entry in owned_files.items()
            if isinstance(relative, str) and isinstance(entry, dict)
        }

    if apply:
        _run_rendering_gate(source_path)

    pin_entries, _ = _source_files(source_path, copy_set=False)
    copy_entries, excluded = _source_files(source_path, copy_set=True)
    if pin is not None:
        pin_path = Path(pin)
        try:
            pin_data = json.loads(pin_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise Refusal(f"cannot read pin: {pin_path}: {error}") from error
        changed, added, missing, aggregate = _pin_mismatch(pin_entries, pin_data)
        # The reviewed 2026-09-20 pin predates the explicit tree_method field.
        # Its complete per-file map is authoritative; new pins also require the aggregate.
        legacy_complete = "tree_method" not in pin_data and not (changed or added or missing)
        if changed or added or missing or ("tree_method" in pin_data and not aggregate):
            print("PIN_MISMATCH")
            for path in changed:
                print(f"PIN_CHANGED={path}")
            for path in added:
                print(f"PIN_ADDED={path}")
            for path in missing:
                print(f"PIN_MISSING={path}")
            raise Refusal("pin does not match source")
        print("PIN_MATCH=" + ("legacy-file-map" if legacy_complete else "tree-hash"))

    if write_pin is not None:
        pin_output = Path(write_pin)
        pin_output.parent.mkdir(parents=True, exist_ok=True)
        pin_output.write_text(json.dumps(_pin_payload(pin_entries), indent=1, ensure_ascii=False) + "\n", encoding="utf-8")

    before_geo = _geo_hash(target / GEO_RELATIVE)
    existing = _target_files(target)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    actions: list[dict] = []
    refusals: list[dict] = []
    backups: list[str] = []

    _print_exclusions()
    print(f"MODE={'apply' if apply else 'dry-run'}")
    print(f"SOURCE={source_path}")
    print(f"TARGET={target}")
    for relative in sorted(copy_entries):
        destination = target / Path(relative)
        if _forbidden_reason(root_path, destination):
            reason = "excluded vault path"
            print(f"REFUSE {relative}: {reason}")
            refusals.append({"path": relative, "reason": reason})
            continue
        source_bytes = copy_entries[relative]
        if relative == GEO_RELATIVE.as_posix():
            print(f"REFUSE {relative}: protected geo note")
            refusals.append({"path": relative, "reason": "protected geo note"})
            continue
        if destination.exists() and not destination.is_file():
            reason = "target path is not a file"
            print(f"REFUSE {relative}: {reason}")
            refusals.append({"path": relative, "reason": reason})
            continue
        if relative not in existing:
            action = "create"
            print(f"CREATE {relative}")
            actions.append({"path": relative, "action": action})
            if apply:
                _atomic_write(destination, source_bytes)
            continue
        if existing[relative] == source_bytes:
            print(f"UNCHANGED {relative}")
            actions.append({"path": relative, "action": "unchanged"})
            continue
        authored_by, locked = _frontmatter_flags(existing[relative])
        # A file with no frontmatter (canvas, base) is ours only if it matches our last pin.
        owned_entry = owned_entries.get(relative, {})
        owned_by_bytes = owned_entry.get("sha256") == _sha256(existing[relative])
        owned_by_canonical = (
            relative.casefold().endswith(".canvas")
            and isinstance(owned_entry.get("canonical_sha256"), str)
            and owned_entry.get("canonical_sha256") == _canonical_content(relative, existing[relative])
        )
        if authored_by is None and not locked and (owned_by_bytes or owned_by_canonical):
            authored_by = "agent"
        if authored_by != "agent" or locked:
            reason = "locked target" if locked else "target is not authored_by: agent"
            print(f"REFUSE {relative}: {reason}")
            refusals.append({"path": relative, "reason": reason})
            continue
        print(f"UPDATE {relative}")
        actions.append({"path": relative, "action": "update"})
        if apply:
            backup_destination = backup_path / timestamp / Path(relative)
            _atomic_write(backup_destination, existing[relative])
            backups.append(str(backup_destination))
            print(f"BACKUP {backup_destination}")
            _atomic_write(destination, source_bytes)
        else:
            print(f"BACKUP_PLAN {backup_path / timestamp / Path(relative)}")

    for relative in sorted(set(existing) - set(copy_entries)):
        print(f"orphan-kept {relative}")
        actions.append({"path": relative, "action": "orphan-kept"})

    after_geo = _geo_hash(target / GEO_RELATIVE)
    print(f"GEO_SHA256_BEFORE={before_geo}")
    print(f"GEO_SHA256_AFTER={after_geo}")
    result = {
        "source": str(source_path),
        "target": str(target),
        "mode": "apply" if apply else "dry-run",
        "excluded": excluded,
        "actions": actions,
        "refusals": refusals,
        "backup_paths": backups,
        "geo_sha256_before": before_geo,
        "geo_sha256_after": after_geo,
    }
    if report is not None:
        report_path = Path(report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return result


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Safely publish the reviewed Saved AI Posts corpus into its fixed vault folder.")
    parser.add_argument("--source", required=True, type=Path, help="staging publication-dryrun tree")
    parser.add_argument("--vault-root", required=True, type=Path, help="Obsidian vault root")
    parser.add_argument("--apply", action="store_true", help="perform creates and agent-authored updates")
    parser.add_argument("--pin", type=Path, help="reviewed tree pin JSON")
    parser.add_argument("--owned-pin", type=Path, help="pin of the last publish; frontmatter-less targets still matching it may be updated")
    parser.add_argument("--write-pin", type=Path, help="write a new pin JSON for this source tree")
    parser.add_argument("--backup-root", type=Path, help="backup destination outside the vault")
    parser.add_argument("--report", type=Path, help="write a JSON run report")
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    try:
        publish(
            args.source,
            args.vault_root,
            apply=args.apply,
            pin=args.pin,
            backup_root=args.backup_root,
            report=args.report,
            write_pin=args.write_pin,
            owned_pin=args.owned_pin,
        )
    except Refusal as error:
        print(f"REFUSE_RUN: {error}")
        return 2
    except OSError as error:
        print(f"ERROR: {error}")
        return 1
    return 0


if __name__ == "__main__":
    # Filenames carry em dashes; a cp1252 console would crash mid-run without this.
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    raise SystemExit(main())
