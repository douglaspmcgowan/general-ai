#!/usr/bin/env python3
"""Mechanical gate for the Saved AI Posts publication tree."""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable


VAULT_ROOT = "50 Knowledge/57 Corpus/Saved AI Posts"
EXCLUDED = {"Backups", "_review", "_evidence"}
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
TABLE_SEPARATOR_RE = re.compile(r"^\s*\|?\s*:?-{3,}:?\s*(?:\|\s*:?-{3,}:?\s*)+\|?\s*$")


def _split_link(token: str) -> tuple[str, str | None]:
    for index, char in enumerate(token):
        if char == "|":
            if index and token[index - 1] == "\\":
                return token[: index - 1], token[index + 1 :]
            return token[:index], token[index + 1 :]
    return token, None


def _unescape(value: str) -> str:
    return value.replace(r"\|", "|").strip()


def _table_cells(line: str) -> tuple[int, bool]:
    """Return cell count and whether an unescaped pipe occurs inside a wikilink."""
    pipes = 0
    bad_alias = False
    in_link = False
    escaped = False
    index = 0
    while index < len(line):
        if line.startswith("[[", index) and not escaped:
            in_link = True
            index += 2
            escaped = False
            continue
        if line.startswith("]]", index) and in_link and not escaped:
            in_link = False
            index += 2
            escaped = False
            continue
        char = line[index]
        if char == "|" and not escaped:
            pipes += 1
            if in_link:
                bad_alias = True
        if char == "\\" and not escaped:
            escaped = True
        else:
            escaped = False
        index += 1
    return pipes + 1, bad_alias


def _is_table_row(line: str) -> bool:
    return "|" in line and not line.lstrip().startswith("```")


def _table_violations(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    violations: list[str] = []
    index = 0
    while index + 1 < len(lines):
        if _is_table_row(lines[index]) and TABLE_SEPARATOR_RE.match(lines[index + 1]):
            header_count, header_bad = _table_cells(lines[index])
            if header_bad:
                violations.append(f"{path}: table header has unescaped pipe inside wikilink")
            row_index = index + 2
            while row_index < len(lines) and lines[row_index].strip() and _is_table_row(lines[row_index]):
                count, bad = _table_cells(lines[row_index])
                if bad:
                    violations.append(f"{path}:{row_index + 1}: unescaped pipe inside wikilink on table row")
                if count != header_count:
                    violations.append(f"{path}:{row_index + 1}: table cells={count}, header cells={header_count}")
                row_index += 1
            index = row_index
        else:
            index += 1
    return violations


def _rect(node: dict) -> tuple[float, float, float, float]:
    return (
        float(node.get("x", 0)),
        float(node.get("y", 0)),
        float(node.get("x", 0)) + float(node.get("width", 0)),
        float(node.get("y", 0)) + float(node.get("height", 0)),
    )


def _intersects(left: tuple[float, float, float, float], right: tuple[float, float, float, float]) -> bool:
    return max(left[0], right[0]) < min(left[2], right[2]) and max(left[1], right[1]) < min(left[3], right[3])


def _contains(parent: tuple[float, float, float, float], child: tuple[float, float, float, float]) -> bool:
    return parent[0] <= child[0] and parent[1] <= child[1] and parent[2] >= child[2] and parent[3] >= child[3]


def _resolve_path(source: Path, target: str) -> tuple[Path | None, bool]:
    target = target.replace("\\", "/").strip()
    if not target or target.startswith("#"):
        return None, False
    if target.startswith(VAULT_ROOT + "/"):
        return source / target[len(VAULT_ROOT) + 1 :], False
    if target == VAULT_ROOT:
        return source, False
    if target.startswith("50 Knowledge/"):
        return None, True
    candidates = [source / target]
    if not Path(target).suffix:
        candidates.extend(source / (target + suffix) for suffix in (".md", ".canvas", ".base"))
    return next((candidate for candidate in candidates if candidate.is_file()), candidates[0]), False


def _check_canvas(path: Path, source: Path) -> tuple[list[str], Counter]:
    violations: list[str] = []
    counts: Counter = Counter()
    try:
        canvas = json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:
        return [f"{path}: invalid JSON ({error})"], counts
    if not isinstance(canvas, dict) or not isinstance(canvas.get("nodes"), list) or not isinstance(canvas.get("edges"), list):
        return [f"{path}: JSON Canvas must contain nodes and edges arrays"], counts
    nodes = canvas["nodes"]
    edges = canvas["edges"]
    counts.update({"nodes": len(nodes), "groups": sum(node.get("type") == "group" for node in nodes), "edges": len(edges)})
    ids = [node.get("id") for node in nodes] + [edge.get("id") for edge in edges]
    if any(not isinstance(value, str) or not value for value in ids):
        violations.append(f"{path}: every node and edge needs a non-empty id")
    if len(ids) != len(set(ids)):
        violations.append(f"{path}: duplicate node or edge ids")
    node_ids = {node.get("id") for node in nodes}
    rects = {node.get("id"): _rect(node) for node in nodes}
    groups = [node for node in nodes if node.get("type") == "group"]
    for node in nodes:
        node_type = node.get("type")
        if node_type not in {"text", "file", "link", "group"}:
            violations.append(f"{path}: unsupported node type {node_type!r}")
        for field in ("x", "y", "width", "height"):
            if not isinstance(node.get(field), (int, float)):
                violations.append(f"{path}: node {node.get('id')} missing numeric {field}")
        if node_type == "text":
            if not isinstance(node.get("text"), str):
                violations.append(f"{path}: text node {node.get('id')} missing text")
            if float(node.get("width", 0)) < 200 or float(node.get("height", 0)) < 60:
                violations.append(f"{path}: text node {node.get('id')} is below 200x60")
            for token in WIKILINK_RE.findall(node.get("text", "")):
                target, _alias = _split_link(token)
                resolved, outside = _resolve_path(source, _unescape(target).split("#", 1)[0])
                if outside:
                    counts["outside_links"] += 1
                elif resolved is not None and not resolved.is_file():
                    violations.append(f"{path}: unresolved canvas wikilink {_unescape(target)!r}")
        elif node_type == "file":
            if not isinstance(node.get("file"), str):
                violations.append(f"{path}: file node {node.get('id')} missing file")
            elif not node["file"].startswith(VAULT_ROOT + "/"):
                violations.append(f"{path}: file node {node.get('id')} is not vault-root relative")
            else:
                resolved, _outside = _resolve_path(source, node["file"])
                if resolved is None or not resolved.is_file():
                    violations.append(f"{path}: unresolved canvas file {node['file']!r}")
            if float(node.get("width", 0)) < 300 or float(node.get("height", 0)) < 200:
                violations.append(f"{path}: file node {node.get('id')} is below 300x200")
        elif node_type == "link" and not isinstance(node.get("url"), str):
            violations.append(f"{path}: link node {node.get('id')} missing url")
    for edge in edges:
        if edge.get("fromNode") not in node_ids or edge.get("toNode") not in node_ids:
            violations.append(f"{path}: edge {edge.get('id')} has missing endpoint")
        if not edge.get("label"):
            violations.append(f"{path}: unlabeled edge {edge.get('id')}")
    for index, left in enumerate(groups):
        for right in groups[index + 1 :]:
            if _intersects(rects[left.get("id")], rects[right.get("id")]):
                violations.append(f"{path}: groups overlap ({left.get('id')}, {right.get('id')})")
    for node in nodes:
        if node.get("type") == "group":
            continue
        containing = [group for group in groups if _contains(rects[group.get("id")], rects[node.get("id")])]
        partial = [group for group in groups if _intersects(rects[group.get("id")], rects[node.get("id")]) and group not in containing]
        if partial:
            violations.append(f"{path}: node {node.get('id')} spills out of a group")
        parent = min(containing, key=lambda group: float(group.get("width", 0)) * float(group.get("height", 0)), default=None)
        parent_id = parent.get("id") if parent else None
        node["__parent"] = parent_id
    non_groups = [node for node in nodes if node.get("type") != "group"]
    for index, left in enumerate(non_groups):
        for right in non_groups[index + 1 :]:
            if left.get("__parent") == right.get("__parent") and _intersects(rects[left.get("id")], rects[right.get("id")]):
                violations.append(f"{path}: sibling nodes overlap ({left.get('id')}, {right.get('id')})")
    return violations, counts


def check_tree(source: Path) -> tuple[list[str], dict[str, int]]:
    violations: list[str] = []
    counts: Counter = Counter()
    if not source.is_dir():
        return [f"source is not a directory: {source}"], {}
    markdown = [path for path in source.rglob("*.md") if not (set(path.relative_to(source).parts) & EXCLUDED)]
    for path in markdown:
        violations.extend(_table_violations(path))
    canvases = [path for path in source.rglob("*.canvas") if not (set(path.relative_to(source).parts) & EXCLUDED)]
    counts["canvases"] = len(canvases)
    for path in canvases:
        canvas_violations, canvas_counts = _check_canvas(path, source)
        violations.extend(canvas_violations)
        counts.update(canvas_counts)
    for path in markdown:
        for token in WIKILINK_RE.findall(path.read_text(encoding="utf-8", errors="replace")):
            target, _alias = _split_link(token)
            target = _unescape(target).split("#", 1)[0]
            resolved, outside = _resolve_path(source, target)
            if outside:
                counts["outside_links"] += 1
            elif resolved is not None and not resolved.is_file():
                violations.append(f"{path}: unresolved wikilink {target!r}")
            elif resolved is not None:
                counts["wikilinks"] += 1
    manifest = source.parent / "classification" / "entities-v1.json"
    entity_dir = source / "Entities"
    if manifest.is_file():
        expected = len(json.loads(manifest.read_text(encoding="utf-8")).get("entities", []))
        actual = sum(1 for path in entity_dir.glob("*.md") if path.name not in {"README.md", "Entity map.md"})
        counts["entities"] = actual
        if actual != expected:
            violations.append(f"{source}: entity notes={actual}, expected={expected}")
    else:
        counts["entities"] = -1
    counts["table_files"] = len(markdown)
    return violations, dict(counts)


def main(argv: Iterable[str] | None = None) -> int:
    args = list(argv if argv is not None else sys.argv[1:])
    if len(args) != 1:
        print("usage: check_social_rendering.py <publication-dryrun>", file=sys.stderr)
        return 2
    violations, counts = check_tree(Path(args[0]))
    print("CANVASES={canvases} NODES={nodes} GROUPS={groups} EDGES={edges} ENTITIES={entities} OUTSIDE_LINKS={outside_links} VIOLATIONS={violations}".format(
        canvases=counts.get("canvases", 0), nodes=counts.get("nodes", 0), groups=counts.get("groups", 0), edges=counts.get("edges", 0), entities=counts.get("entities", -1), outside_links=counts.get("outside_links", 0), violations=len(violations)
    ))
    for violation in violations:
        print("VIOLATION: " + violation)
    return 1 if violations else 0


if __name__ == "__main__":
    raise SystemExit(main())
