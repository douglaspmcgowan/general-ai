#!/usr/bin/env python3
"""Mechanical gate for the Saved AI Posts publication tree."""
from __future__ import annotations

import json
import hashlib
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable


VAULT_ROOT = "50 Knowledge/57 Corpus/Saved AI Posts"
EXCLUDED = {"Backups", "_review", "_evidence"}
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
DETAIL_TOPICS = {
    "ai news.canvas": "ai-news",
    "design tools.canvas": "design-tools",
    "cad and 3d.canvas": "cad-and-3d",
    "agents and coding.canvas": "agents-and-coding",
    "research.canvas": "research",
    "workflows and productivity.canvas": "workflows-and-productivity",
    "business.canvas": "business",
    "hardware.canvas": "hardware",
    "security.canvas": "security",
    "unsorted.canvas": "unsorted",
}
TABLE_SEPARATOR_RE = re.compile(r"^\s*\|?\s*:?-{3,}:?\s*(?:\|\s*:?-{3,}:?\s*)+\|?\s*$")
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")


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


def _frontmatter_fields(text: str) -> dict[str, str | None]:
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 4)
    if end < 0:
        return {}
    fields: dict[str, str | None] = {}
    for line in text[4:end].splitlines():
        if ":" not in line:
            continue
        key, raw = line.split(":", 1)
        key = key.strip()
        value = raw.strip()
        if value.lower() in {"", "null", "~"}:
            fields[key] = None
            continue
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError:
            parsed = value.strip("'\"")
        fields[key] = None if parsed is None else str(parsed)
    return fields


def _source_note_permalink_violations(source: Path) -> list[str]:
    notes = source / "Notes"
    if not notes.is_dir():
        return []
    violations: list[str] = []
    for path in sorted(notes.glob("*.md")):
        if path.name == "README.md":
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        fields = _frontmatter_fields(text)
        if fields.get("subtype") != "source":
            continue
        permalink = fields.get("permalink")
        if permalink is None:
            continue
        destinations = []
        for match in MARKDOWN_LINK_RE.finditer(text):
            destination = match.group(1).strip()
            if destination.startswith("<") and ">" in destination:
                destination = destination[1:destination.index(">")]
            else:
                destination = destination.split(None, 1)[0]
            destinations.append(destination)
        if permalink not in destinations:
            violations.append(f"{path}: permalink {permalink!r} is missing from the body as a markdown link")
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


def _side_point(rect: tuple[float, float, float, float], side: str) -> tuple[float, float] | None:
    left, top, right, bottom = rect
    if side == "left":
        return left, (top + bottom) / 2
    if side == "right":
        return right, (top + bottom) / 2
    if side == "top":
        return (left + right) / 2, top
    if side == "bottom":
        return (left + right) / 2, bottom
    return None


def _orientation(a: tuple[float, float], b: tuple[float, float], c: tuple[float, float]) -> float:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _segments_cross(left: tuple[tuple[float, float], tuple[float, float]], right: tuple[tuple[float, float], tuple[float, float]]) -> bool:
    a, b = left
    c, d = right
    values = (_orientation(a, b, c), _orientation(a, b, d), _orientation(c, d, a), _orientation(c, d, b))
    return ((values[0] > 0 > values[1]) or (values[0] < 0 < values[1])) and ((values[2] > 0 > values[3]) or (values[2] < 0 < values[3]))


def _edge_crossings(edges: list[dict], rects: dict[str, tuple[float, float, float, float]]) -> int:
    segments: list[tuple[dict, tuple[tuple[float, float], tuple[float, float]]]] = []
    for edge in edges:
        if edge.get("fromNode") not in rects or edge.get("toNode") not in rects:
            continue
        from_point = _side_point(rects[edge["fromNode"]], str(edge.get("fromSide", "")))
        to_point = _side_point(rects[edge["toNode"]], str(edge.get("toSide", "")))
        if from_point is not None and to_point is not None:
            segments.append((edge, (from_point, to_point)))
    crossings = 0
    for index, (left_edge, left_segment) in enumerate(segments):
        for right_edge, right_segment in segments[index + 1 :]:
            if {left_edge.get("fromNode"), left_edge.get("toNode")} & {right_edge.get("fromNode"), right_edge.get("toNode")}:
                continue
            crossings += int(_segments_cross(left_segment, right_segment))
    return crossings


def _entity_filename_map(entities: list[dict]) -> dict[str, str]:
    used: dict[str, str] = {}
    filenames: dict[str, str] = {}
    invalid = re.compile(r'[<>:"/\\|?*\x00-\x1f]')
    reserved = {"CON", "PRN", "AUX", "NUL", *(f"COM{i}" for i in range(1, 10)), *(f"LPT{i}" for i in range(1, 10))}
    for entity in sorted(entities, key=lambda row: str(row["canonical"]).casefold()):
        canonical = str(entity["canonical"]).strip()
        stem = canonical if canonical.casefold().endswith(".md") else canonical + ".md"
        safe = invalid.sub(" - ", stem).rstrip(" .")
        if safe.split(".")[0].upper() in reserved:
            safe = "_" + safe
        if not safe:
            safe = "unnamed-entity.md"
        if safe.casefold() in used and used[safe.casefold()] != canonical:
            safe = safe[:-3] + " — " + hashlib.sha1(canonical.encode("utf-8")).hexdigest()[:8] + ".md"
        used[safe.casefold()] = canonical
        filenames[canonical] = safe
    return filenames


def _detail_entity_violations(path: Path, source: Path, nodes: list[dict]) -> list[str]:
    topic = DETAIL_TOPICS.get(path.name.casefold())
    if not topic:
        return []
    classification = source.parent / "classification"
    entities_path = classification / "entities-v1.json"
    topics_path = classification / "primary-topics-v2.json"
    if not entities_path.is_file() or not topics_path.is_file():
        return []
    try:
        entities = json.loads(entities_path.read_text(encoding="utf-8")).get("entities", [])
        overlay = {str(row["stable_id"]): str(row["primary_topic"]) for row in json.loads(topics_path.read_text(encoding="utf-8"))}
    except (OSError, KeyError, TypeError, json.JSONDecodeError):
        return []
    category_ids = {stable_id for stable_id, assigned_topic in overlay.items() if assigned_topic == topic}
    filenames = _entity_filename_map(entities)
    allowed = {
        f"{VAULT_ROOT}/Entities/{filenames[str(entity['canonical'])]}"
        for entity in entities
        if any(
            pointer.get("source") == "collection"
            and str(pointer.get("stable_id")) in category_ids
            for pointer in entity.get("pointers", [])
        )
    }
    all_entities = {f"{VAULT_ROOT}/Entities/{filename}" for filename in filenames.values()}
    violations: list[str] = []
    for node in nodes:
        if node.get("type") != "text":
            continue
        for token in WIKILINK_RE.findall(str(node.get("text", ""))):
            target, _alias = _split_link(token)
            target = _unescape(target).split("#", 1)[0]
            if target in all_entities and target not in allowed:
                violations.append(f"{path}: entity card {node.get('id')} for {target!r} does not belong to category {topic}")
    return violations


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


def _line_words(value: str) -> int:
    return len(re.findall(r"\S+", value.strip()))


def _looks_like_shortcode(token: str) -> bool:
    return len(token) >= 8 and token.startswith("D") and (any(character.isdigit() for character in token) or "_" in token or sum(character.isupper() for character in token) >= 2)


def _card_lines_violations(source: Path) -> list[str]:
    path = source.parent / "classification" / "card-lines-v1.json"
    if not path.is_file():
        return []
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"{path}: invalid card-lines JSON ({error})"]
    violations: list[str] = []
    lines: list[tuple[str, str]] = []
    for topic, entry in payload.get("categories", {}).items():
        line = str(entry.get("line", ""))
        lines.append((f"category {topic}", line))
        if _line_words(line) > 14:
            violations.append(f"{path}: category line {topic!r} exceeds 14 words")
    comparisons_dir = path.parent / "comparisons"
    source_summaries: list[str] = []
    if comparisons_dir.is_dir():
        for comparison in comparisons_dir.glob("*.json"):
            if comparison.name.startswith("_"):
                continue
            try:
                document = json.loads(comparison.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue
            for cluster in document.get("clusters", []):
                source_summaries.append(str(cluster.get("summary", {}).get("text", "")))
                source_summaries.extend(str(item.get("text", "")) for item in cluster.get("comparison", []))
            source_summaries.append(str(document.get("headline", "")))
    for topic, clusters in payload.get("clusters", {}).items():
        for name, entry in clusters.items():
            line = str(entry.get("line", ""))
            lines.append((f"cluster {topic}/{name}", line))
            if _line_words(line) > 12:
                violations.append(f"{path}: cluster line {topic}/{name!r} exceeds 12 words")
    for index, relation in enumerate(payload.get("relations", [])):
        line = str(relation.get("line", ""))
        if relation.get("line_kind") == "data":
            # A data label lists shared names; it must match the data exactly and is exempt from prose rules.
            shared = relation.get("shared_entities") or []
            expected = "shared: " + ", ".join(shared[:3]) if shared else f"{len(relation.get('shared_posts') or [])} shared posts"
            if line != expected:
                violations.append(f"{path}: relation {index} data label does not match its shared data")
            continue
        lines.append((f"relation {index}", line))
        if _line_words(line) > 8:
            violations.append(f"{path}: relation {index} exceeds 8 words")
        if not relation.get("shared_entities") and not relation.get("shared_posts"):
            violations.append(f"{path}: relation {index} has no grounded overlap")
    first_four: dict[str, str] = {}
    for owner, line in lines:
        if not line.strip():
            violations.append(f"{path}: {owner} has an empty line")
            continue
        if any(_looks_like_shortcode(token.strip(".,:;()[]")) for token in line.split()):
            violations.append(f"{path}: {owner} contains a shortcode-like token")
        prefix = " ".join(line.split()[:4]).casefold()
        if prefix in first_four:
            violations.append(f"{path}: {owner} shares its first four words with {first_four[prefix]}")
        else:
            first_four[prefix] = owner
        lowered = line.casefold()
        if any(lowered in summary.casefold() for summary in source_summaries if lowered):
            violations.append(f"{path}: {owner} is a source-summary substring")
    return violations


def _canvas_bounds(path: Path, nodes: list[dict]) -> tuple[float, float]:
    if not nodes:
        return 0.0, 0.0
    min_x = min(float(node.get("x", 0)) for node in nodes)
    min_y = min(float(node.get("y", 0)) for node in nodes)
    max_x = max(float(node.get("x", 0)) + float(node.get("width", 0)) for node in nodes)
    max_y = max(float(node.get("y", 0)) + float(node.get("height", 0)) for node in nodes)
    return max_x - min_x, max_y - min_y


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
    bound_width, bound_height = _canvas_bounds(path, nodes)
    max_width, max_height = ((2600, 1800) if path.name.casefold() == "saved ai posts.canvas" else (3200, 2200))
    if bound_width > max_width or bound_height > max_height:
        violations.append(f"{path}: bounding box {bound_width:g}x{bound_height:g} exceeds {max_width}x{max_height}")
    ids = [node.get("id") for node in nodes] + [edge.get("id") for edge in edges]
    if any(not isinstance(value, str) or not value for value in ids):
        violations.append(f"{path}: every node and edge needs a non-empty id")
    if len(ids) != len(set(ids)):
        violations.append(f"{path}: duplicate node or edge ids")
    node_ids = {node.get("id") for node in nodes}
    rects = {node.get("id"): _rect(node) for node in nodes}
    groups = [node for node in nodes if node.get("type") == "group"]
    violations.extend(_detail_entity_violations(path, source, nodes))
    for group in groups:
        width = float(group.get("width", 0))
        height = float(group.get("height", 0))
        if width > 0 and height / width > 4:
            violations.append(f"{path}: group {group.get('id')} aspect ratio {height / width:.2f} exceeds 4")
        if height > 2400:
            violations.append(f"{path}: group {group.get('id')} height {height:g} exceeds 2400")
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
            else:
                first_line = next((line.strip() for line in node["text"].splitlines() if line.strip()), "")
                if not first_line.startswith("#"):
                    violations.append(f"{path}: text node {node.get('id')} first line is not a heading")
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
        requires_sides = path.name.casefold() == "saved ai posts.canvas" or path.parent.name.casefold() == "canvases"
        if requires_sides and (edge.get("fromSide") not in {"left", "right", "top", "bottom"} or edge.get("toSide") not in {"left", "right", "top", "bottom"}):
            violations.append(f"{path}: edge {edge.get('id')} missing fromSide/toSide")
        if not edge.get("label") and path.parent.name.casefold() != "canvases":
            violations.append(f"{path}: unlabeled edge {edge.get('id')}")
    if path.parent.name.casefold() == "canvases":
        group_ids = {node.get("id") for node in groups}
        card_lines_path = source.parent / "classification" / "card-lines-v1.json"
        hand_written = set()
        try:
            card_lines = json.loads(card_lines_path.read_text(encoding="utf-8"))
            hand_written = {str(item.get("line")) for item in card_lines.get("relations", []) if item.get("line_kind") == "hand-written"}
        except (OSError, json.JSONDecodeError):
            pass
        for edge in edges:
            if edge.get("fromNode") in group_ids and edge.get("toNode") in group_ids and edge.get("label") not in hand_written:
                violations.append(f"{path}: cluster-to-cluster edge {edge.get('id')} lacks a hand-written line")
    for group in groups:
        children = [node for node in nodes if node.get("type") != "group" and _contains(rects[group.get("id")], rects[node.get("id")])]
        if not children:
            violations.append(f"{path}: group {group.get('id')} has no children")
            continue
        summary = min(children, key=lambda node: (float(node.get("y", 0)), float(node.get("x", 0))))
        if summary.get("type") != "text" or not next((line.strip() for line in str(summary.get("text", "")).splitlines() if line.strip()), "").startswith("#"):
            violations.append(f"{path}: group {group.get('id')} top-most child is not a summary card")
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
    if path.name.casefold() == "saved ai posts.canvas":
        classification_dir = source.parent / "classification"
        comparison_dir = classification_dir / "comparisons"
        category_sets: dict[str, set[str]] = {}
        try:
            entities = json.loads((classification_dir / "entities-v1.json").read_text(encoding="utf-8")).get("entities", [])
            topics = json.loads((classification_dir / "primary-topics-v2.json").read_text(encoding="utf-8"))
            ids_by_topic: dict[str, set[str]] = defaultdict(set)
            for item in topics:
                ids_by_topic[str(item.get("primary_topic"))].add(str(item.get("stable_id")))
            for topic, record_ids in ids_by_topic.items():
                category_sets[topic] = {str(entity.get("canonical")) for entity in entities if any(pointer.get("source") == "collection" and str(pointer.get("stable_id")) in record_ids for pointer in entity.get("pointers", []))}
        except (OSError, json.JSONDecodeError, TypeError):
            category_sets = {}
        heading_to_topic = {}
        for node in nodes:
            if node.get("type") != "text":
                continue
            first = next((line.strip() for line in str(node.get("text", "")).splitlines() if line.strip()), "")
            if first.startswith("## "):
                label = first[3:].strip().casefold().replace(" ", "-")
                heading_to_topic[node.get("id")] = label
        ubiquitous = {name for values in category_sets.values() for name in values if sum(name in candidate for candidate in category_sets.values()) >= 5}
        for edge in edges:
            left_topic = heading_to_topic.get(edge.get("fromNode")); right_topic = heading_to_topic.get(edge.get("toNode"))
            if left_topic and right_topic and left_topic in category_sets and right_topic in category_sets:
                shared = category_sets[left_topic] & category_sets[right_topic]
                meaningful = shared - ubiquitous
                if len(meaningful) < 2:
                    violations.append(f"{path}: top-canvas edge {edge.get('id')} lacks two non-ubiquitous shared entities")
        crossings = _edge_crossings(edges, rects)
        counts["crossings"] = crossings
        if crossings > 3:
            violations.append(f"{path}: top-canvas edge crossings={crossings} exceeds 3")
    else:
        counts["crossings"] = _edge_crossings(edges, rects)
    return violations, counts


def check_tree(source: Path) -> tuple[list[str], dict[str, int]]:
    violations: list[str] = []
    counts: Counter = Counter()
    if not source.is_dir():
        return [f"source is not a directory: {source}"], {}
    violations.extend(_card_lines_violations(source))
    violations.extend(_source_note_permalink_violations(source))
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
