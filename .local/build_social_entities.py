"""Render the analysed entity, comparison, and canvas layer for Saved AI Posts."""
from __future__ import annotations

import hashlib
import json
import math
import os
import re
from collections import defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(r"C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919")
CLASSIFICATION = ROOT / "classification"
COMPARISONS = CLASSIFICATION / "comparisons"
PUBLICATION = Path(os.environ.get("SOCIAL_PUBLICATION_DIR", str(ROOT / "publication-dryrun")))
ENTITY_JSON = CLASSIFICATION / "entities-v1.json"
READINGS_JSON = CLASSIFICATION / "entity-readings-v1.json"
TOPIC_JSON = CLASSIFICATION / "primary-topics-v2.json"
CATALOG_JSON = CLASSIFICATION / "catalog-records-v3.json"
COMPARISON_INDEX = CLASSIFICATION / "comparisons-v1.json"
CROSS_JSON = COMPARISONS / "_cross-category.json"
QA_PATH = ROOT / "qa" / "compare-canvas-evidence-20260921.md"
CONTRACT_PATH = ROOT / "plan" / "vault-publication-contract.md"

VAULT_ROOT = "50 Knowledge/57 Corpus/Saved AI Posts"
TOPIC_LABELS = {
    "ai-news": "AI news",
    "design-tools": "Design tools",
    "cad-and-3d": "CAD and 3D",
    "agents-and-coding": "Agents and coding",
    "research": "Research",
    "workflows-and-productivity": "Workflows and productivity",
    "business": "Business",
    "hardware": "Hardware",
    "security": "Security",
    "unsorted": "Unsorted",
}
INLINE_IDS = re.compile(r"\s*\[(?:dm|[A-Za-z0-9_-]{6,})(?:(?:\s*[,;]\s*|\s+)(?:dm|[A-Za-z0-9_-]{6,}))*\s*\]")
BARE_ID = re.compile(r"(?<![A-Za-z0-9_-])D[A-Za-z0-9_-]{8,}(?![A-Za-z0-9_-])")
WIKILINK = re.compile(r"\[\[[^]]+\]\]")


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    except PermissionError:
        if not path.exists():
            raise


def clean(value: Any) -> str:
    return re.sub(r"\s+", " ", str(value if value is not None else "")).strip()


def slug(value: str, limit: int = 90) -> str:
    value = clean(value).lower().replace("&", " and ")
    value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    return (value[:limit].strip("-") or "unnamed")


def source_filename(record: dict[str, Any]) -> str:
    return f"{slug(record.get('title') or 'unresolved title')} — {record['stable_id']}.md"


def vault_link(path: str, label: str, *, table: bool = False) -> str:
    """Render a vault-root wikilink, escaping the alias separator in tables."""
    separator = r"\|" if table else "|"
    return f"[[{VAULT_ROOT}/{path}{separator}{label}]]"


def source_link(stable_id: str, records: dict[str, dict[str, Any]], *, table: bool = False) -> str:
    record = records.get(str(stable_id))
    if not record:
        return ""
    return vault_link(f"Notes/{source_filename(record)}", clean(record.get("title")) or str(stable_id), table=table)


def yaml_value(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    return json.dumps(str(value), ensure_ascii=False)


def folder_readme(title_text: str, sentence: str, links: list[tuple[str, str]]) -> str:
    lines = [
        "---", "type: index", f"title: {yaml_value(title_text)}", "authored_by: agent",
        "maintained_by: agent", "status: current", "corpus: Saved AI Posts",
        'tags: ["index", "corpus/saved-ai-posts", "agent-note"]', 'updated: "2026-09-21"',
        "---", "", f"# {title_text}", "", sentence, "",
    ]
    lines.extend(f"- {vault_link(path, label)}" for path, label in links)
    return "\n".join(lines) + "\n"


def ensure_agent_note_tags() -> None:
    for path in PUBLICATION.rglob("*.md"):
        relative = path.relative_to(PUBLICATION).parts
        if any(part in {"Backups", "_review", "_evidence"} for part in relative):
            continue
        text = path.read_text(encoding="utf-8")
        if not text.startswith("---\n"):
            continue
        end = text.find("\n---", 4)
        if end < 0:
            continue
        header = text[4:end]
        if not re.search(r"(?m)^authored_by:\s*agent\s*$", header) or "agent-note" in header:
            continue
        lines = header.splitlines()
        tag_index = next((i for i, line in enumerate(lines) if line.startswith("tags:")), None)
        if tag_index is not None and "]" in lines[tag_index]:
            lines[tag_index] = lines[tag_index].replace("]", ', "agent-note"]', 1)
        else:
            author_index = next(i for i, line in enumerate(lines) if line.startswith("authored_by:"))
            lines.insert(author_index + 1, 'tags: ["agent-note"]')
        path.write_text("---\n" + "\n".join(lines) + text[end:], encoding="utf-8", newline="\n")


def ensure_corpus_index_links() -> None:
    index = PUBLICATION / "00 - Saved AI Posts Corpus Index.md"
    if not index.exists():
        return
    text = index.read_text(encoding="utf-8")
    section = "\n## Folder indexes\n\n" + "\n".join([
        f"- {vault_link('Notes/README.md', 'Notes')}",
        f"- {vault_link('Topics/README.md', 'Topics')}",
        f"- {vault_link('Entities/README.md', 'Entities')}",
        f"- {vault_link('Comparisons/README.md', 'Comparisons')}",
    ])
    if "## Folder indexes" not in text:
        text = text.rstrip() + "\n" + section + "\n"
    canvas_section = "\n## Canvas maps\n\n" + "\n".join(
        [f"- {vault_link('Saved AI Posts.canvas', 'Saved AI Posts overview canvas')}" ] +
        [f"- {vault_link('Canvases/' + canvas_filename(topic), TOPIC_LABELS[topic] + ' detail canvas')}" for topic in TOPIC_LABELS]
    ) + "\n"
    if "## Canvas maps" not in text:
        text = text.rstrip() + "\n" + canvas_section
    index.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def quote(value: Any) -> str:
    return clean(value).replace('"', "“")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verified_external_targets() -> set[str]:
    if not CONTRACT_PATH.exists():
        return set()
    return set(re.findall(r"`(50 Knowledge/[^`]+)`", CONTRACT_PATH.read_text(encoding="utf-8")))


def strip_inline_ids(text: str) -> str:
    value = INLINE_IDS.sub("", str(text))
    value = BARE_ID.sub("", value)
    value = re.sub(r"\s+([,.;:])", r"\1", value)
    return clean(value)


def cited_links(cites: list[str], records: dict[str, dict[str, Any]]) -> list[str]:
    links: list[str] = []
    for cite in cites:
        if str(cite) == "dm":
            continue
        link = source_link(str(cite), records)
        if link and link not in links:
            links.append(link)
    return links


def render_entry(entry: dict[str, Any], records: dict[str, dict[str, Any]]) -> str:
    raw = INLINE_IDS.sub("", str(entry.get("text", "")))
    text = clean(BARE_ID.sub(lambda match: source_link(match.group(0), records), raw))
    links = [link for link in cited_links([str(x) for x in entry.get("cites", [])], records) if link not in text]
    return text + ((" " if text else "") + " ".join(links) if links else "")


def headline_entry(text: str) -> dict[str, Any]:
    cites: list[str] = []
    for match in INLINE_IDS.findall(text):
        cites.extend(x for x in re.split(r"\s+", match.strip("[] ")) if x)
    return {"text": text, "cites": cites}


def entity_filename_map(entities: list[dict[str, Any]]) -> tuple[dict[str, str], dict[str, bool]]:
    used: dict[str, str] = {}
    filenames: dict[str, str] = {}
    sanitised: dict[str, bool] = {}
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
        sanitised[canonical] = safe != stem
    return filenames, sanitised


def entity_link(entity: dict[str, Any], filenames: dict[str, str], *, table: bool = False) -> str:
    return vault_link(f"Entities/{filenames[entity['canonical']]}", str(entity["canonical"]), table=table)


def rewrite_entity_links(filenames: dict[str, str]) -> None:
    """Point pre-existing publication notes at the canonical entity filenames."""
    for canonical, filename in filenames.items():
        old = f"Entities/{slug(canonical)}.md"
        new = f"Entities/{filename}"
        if old == new:
            continue
        for path in PUBLICATION.rglob("*.md"):
            if any(part in {"Backups", "_review", "_evidence"} for part in path.relative_to(PUBLICATION).parts):
                continue
            text = path.read_text(encoding="utf-8")
            replaced = text.replace(old, new)
            if replaced != text:
                path.write_text(replaced, encoding="utf-8", newline="\n")


def append_source_entity_links(entities: list[dict[str, Any]], records: dict[str, dict[str, Any]], filenames: dict[str, str]) -> None:
    """Add a deterministic entity section to each source note that mentions one."""
    by_id: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for entity in entities:
        for pointer in entity.get("pointers", []):
            if pointer.get("source") == "collection":
                by_id[str(pointer.get("stable_id"))].append(entity)
    for stable_id, record in records.items():
        path = PUBLICATION / "Notes" / source_filename(record)
        if not path.exists():
            continue
        linked = sorted(by_id.get(str(stable_id), []), key=lambda row: str(row["canonical"]).casefold())
        if not linked:
            continue
        text = path.read_text(encoding="utf-8")
        if "\n## Entities\n" in text:
            continue
        section = "\n## Entities\n\n" + "\n".join(
            f"- {entity_link(entity, filenames)}" for entity in linked
        ) + "\n"
        path.write_text(text.rstrip() + "\n" + section, encoding="utf-8", newline="\n")


def entity_map_note(entities: list[dict[str, Any]], filenames: dict[str, str]) -> str:
    lines = [
        "---", "type: index", 'title: "Saved AI Posts — Entity map"', "authored_by: agent",
        "maintained_by: agent", "status: current", "corpus: Saved AI Posts",
        'tags: ["index", "corpus/saved-ai-posts", "agent-note"]', 'updated: "2026-09-21"',
        "---", "", "# Saved AI Posts — Entity map", "", "Every classified entity, grouped by category and kind; rows are sorted by pointer count (descending).", "",
    ]
    by_category: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(lambda: defaultdict(list))
    for entity in entities:
        category = str(entity.get("primary_category") or "unsorted")
        by_category[category][str(entity.get("kind") or "unknown")].append(entity)
    for category in sorted(by_category, key=str.casefold):
        lines.extend([f"## {TOPIC_LABELS.get(category, category)}", ""])
        for kind in sorted(by_category[category], key=str.casefold):
            lines.extend([f"### {kind}", "", "| Entity | Kind | Pointer count |", "| --- | --- | ---: |"])
            rows = sorted(by_category[category][kind], key=lambda row: (-int(row.get("pointer_count", 0)), str(row["canonical"]).casefold()))
            lines.extend(
                f"| {entity_link(entity, filenames, table=True)} | {kind} | {int(entity.get('pointer_count', 0))} |"
                for entity in rows
            )
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def pointer_groups(entity: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for pointer in entity.get("pointers", []):
        grouped[str(pointer.get("stable_id"))].append(pointer)
    return grouped


def entity_note(entity: dict[str, Any], reading: dict[str, Any], records: dict[str, dict[str, Any]], filenames: dict[str, str], sanitised: dict[str, bool]) -> str:
    canonical = str(entity["canonical"])
    pointer_count = int(entity.get("pointer_count", 0))
    aliases = entity.get("aliases") or []
    if pointer_count < 2:
        # Single-pointer notes intentionally contain data only: no generated prose.
        lines = [
            "---", "type: thing", "subtype: entity", f"title: {yaml_value(canonical)}", "authored_by: agent",
            "maintained_by: agent", "status: current", "corpus: Saved AI Posts",
            f"kind: {yaml_value(entity.get('kind') or 'unknown')}", f"aliases: {yaml_value(aliases)}",
            f"category: {yaml_value(entity.get('primary_category') or 'unsorted')}",
            f"pointer_count: {pointer_count}", 'tags: ["corpus/saved-ai-posts", "entity", "agent-note"]',
            'updated: "2026-09-21"', "---", "", f"# {canonical}", "",
            "- Aliases: " + (", ".join(str(alias) for alias in aliases) if aliases else "none"),
            "- Category: " + str(entity.get("primary_category") or "unsorted"),
            f"- Pointer count: {pointer_count}", "- Source notes:",
        ]
        for pointer in entity.get("pointers", []):
            if pointer.get("source") == "collection":
                source = source_link(str(pointer.get("stable_id")), records)
                if source:
                    lines.append(f"  - {source}")
        if sanitised.get(canonical):
            lines.extend(["", f"Filename: `{filenames[canonical]}` (sanitised from the canonical name for filesystem safety)."])
        return "\n".join(lines) + "\n"
    lines = [
        "---", "type: thing", "subtype: entity", f"title: {yaml_value(canonical)}", "authored_by: agent",
        "maintained_by: agent", "status: current", "corpus: Saved AI Posts",
        f"kind: {yaml_value(entity.get('kind') or 'unknown')}", f"family: {yaml_value(entity.get('family'))}",
        f"pointer_count: {entity.get('pointer_count', 0)}", f"collection_pointer_count: {entity.get('collection_pointer_count', 0)}",
        f"dm_pointer_count: {entity.get('dm_pointer_count', 0)}", f"primary_category: {yaml_value(entity.get('primary_category'))}",
        f"canonical_url: {yaml_value(entity.get('canonical_url'))}", 'tags: ["corpus/saved-ai-posts", "entity", "agent-note"]',
        'updated: "2026-09-21"', "---", "", f"# {canonical}", "", "## What it is", "",
        render_entry(reading["what_it_is"], records), "", "## Reading", "",
    ]
    for item in reading.get("reading", []):
        lines.extend([render_entry(item, records), ""])
    lines.extend(["", "## Consensus or split", "", render_entry(reading["consensus_or_split"], records), "", "## Best pointer", ""])
    best = reading["best_pointer"]
    best_link = source_link(str(best.get("id")), records)
    lines.append(f"- {clean(best.get('why'))}{(' — ' + best_link) if best_link else ''}")
    lines.extend(["", "## Pointers", ""])
    for stable_id in sorted(pointer_groups(entity)):
        pointers = pointer_groups(entity)[stable_id]
        collection = next((p for p in pointers if p.get("source") == "collection"), None)
        dm = next((p for p in pointers if p.get("source") == "dm"), None)
        if collection:
            span = quote(collection.get("evidence_span")) or "evidence span not recorded"
            line = f"- {source_link(stable_id, records)} — \"{span}\""
            if dm:
                line += " — direct-message resource also recorded"
            lines.append(line)
        elif dm:
            span = quote(dm.get("evidence_span")) or "public resource; no private message content is retained"
            lines.append(f"- direct-message resource — \"{span}\"")
    if sanitised.get(canonical):
        lines.extend(["", f"Filename: `{filenames[canonical]}` (sanitised from the canonical name for filesystem safety)."])
    return "\n".join(lines) + "\n"


def topic_entities(topic_doc: dict[str, Any], by_name: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    names = {name for cluster in topic_doc["clusters"] for name in cluster["entities"]}
    missing = names - set(by_name)
    if missing:
        raise RuntimeError(f"comparison file {topic_doc.get('topic')} names unknown entities: {sorted(missing)}")
    return [by_name[name] for name in sorted(names, key=str.casefold)]


def category_pointer_count(entity: dict[str, Any], topic: str, record_ids: set[str]) -> int:
    return len({str(p.get("stable_id")) for p in entity.get("pointers", []) if p.get("source") == "collection" and str(p.get("stable_id")) in record_ids})


def comparison_note(topic: str, doc: dict[str, Any], records: dict[str, dict[str, Any]], entities: list[dict[str, Any]], filenames: dict[str, str]) -> tuple[str, list[dict[str, Any]]]:
    topic_records = {str(x) for cluster in doc["clusters"] for x in cluster["post_ids"]}
    lines = [
        "---", "type: note", f"title: {yaml_value(TOPIC_LABELS[topic] + ' — comparison')}", "authored_by: agent",
        "maintained_by: agent", "status: current", "corpus: Saved AI Posts", f"topic: {yaml_value(topic)}",
        'tags: ["comparison", "corpus/saved-ai-posts", "agent-note"]', 'updated: "2026-09-21"', "---", "",
        f"# {TOPIC_LABELS[topic]} — comparison", "", render_entry(headline_entry(doc["headline"]), records), "",
        "## Entities", "", "| Entity | Kind | Category pointers | Corpus pointers | Evidence pointer |", "| --- | --- | ---: | ---: | --- |",
    ]
    by_name = {e["canonical"]: e for e in entities}
    for entity in sorted(entities, key=lambda e: (-category_pointer_count(e, topic, topic_records), str(e["canonical"]).casefold())):
        pointer = next((p for p in entity.get("pointers", []) if p.get("source") == "collection" and str(p.get("stable_id")) in topic_records), None)
        evidence = quote(pointer.get("evidence_span")) if pointer else ""
        evidence_cell = f"{source_link(str(pointer.get('stable_id')), records, table=True)} — \"{evidence}\"" if pointer else ""
        lines.append(f"| {entity_link(entity, filenames, table=True)} | {clean(entity.get('kind')) or 'unknown'} | {category_pointer_count(entity, topic, topic_records)} | {entity.get('collection_pointer_count', 0)} | {evidence_cell} |")
    lines.extend(["", "## Clusters", ""])
    for cluster in doc["clusters"]:
        lines.extend([f"### {cluster['name']}", "", "Posts", ""])
        lines.extend(f"- {source_link(post_id, records)}" for post_id in cluster["post_ids"])
        lines.extend(["", "Entities", ""])
        for name in cluster["entities"]:
            lines.append(f"- {entity_link(by_name[name], filenames)} — {by_name[name].get('collection_pointer_count', 0)} corpus pointers")
        singleton = [by_name[name] for name in cluster["entities"] if int(by_name[name].get("pointer_count", 0)) == 1]
        lines.extend(["", "Singleton entities", "", f"- {', '.join(e['canonical'] for e in singleton) if singleton else 'None recorded'}", "", "Summary", "", render_entry(cluster["summary"], records), "", "Comparison", ""])
        for item in cluster["comparison"]:
            lines.extend([render_entry(item, records), ""])
    lines.extend(["", "## Thin evidence", ""])
    for item in doc.get("thin_evidence", []):
        lines.extend([render_entry(item, records), ""])
    lines.extend(["", "## What to try first", ""])
    for item in doc.get("try_first", []):
        lines.append(f"- {render_entry(item, records)}")
    lines.extend(["", "## Members", ""])
    for post_id in sorted(topic_records):
        lines.append(f"- {source_link(post_id, records)}")
    return "\n".join(lines) + "\n", [{"text": doc["headline"], "cites": headline_entry(doc["headline"])["cites"]}]


def cross_category_note(doc: dict[str, Any], topic_data: dict[str, Any], records: dict[str, dict[str, Any]], by_name: dict[str, dict[str, Any]], filenames: dict[str, str]) -> str:
    lines = [
        "---", "type: note", 'title: "Cross-category comparison"', "authored_by: agent", "maintained_by: agent", "status: current", "corpus: Saved AI Posts",
        'tags: ["comparison", "cross-category", "corpus/saved-ai-posts", "agent-note"]', 'updated: "2026-09-21"', "---", "",
        "# Cross-category comparison", "", "## Entities spanning categories", "",
    ]
    for item in doc.get("spanning_entities", []):
        lines.extend([render_entry(item, records), ""])
    lines.extend(["", "## Category size, evidence, and actionability", "", "| Category | Posts | Entities | Multi-pointer entities | Needs-review share | Clusters |", "| --- | ---: | ---: | ---: | ---: | ---: |"])
    for topic in TOPIC_LABELS:
        data = topic_data[topic]
        weak = sum(1 for r in data["records"] if r.get("verification_status") in {"needs-review", "unreviewed"} or r.get("usefulness_rating") == "low")
        share = weak / len(data["records"]) if data["records"] else 0
        lines.append(f"| {vault_link('Comparisons/' + slug(TOPIC_LABELS[topic]) + ' — comparison.md', TOPIC_LABELS[topic], table=True)} | {len(data['records'])} | {len(data['entities'])} | {sum(1 for e in data['entities'] if int(e.get('pointer_count', 0)) >= 2)} | {share:.1%} | {len(data['clusters'])} |")
    lines.extend(["", "## Clusters worth Douglas's time", ""])
    for item in doc.get("priority_clusters", []):
        lines.extend([render_entry(item, records), ""])
    return "\n".join(lines) + "\n"


def canvas_filename(topic: str) -> str:
    """Use stable, human-readable filenames that resolve from the publication root."""
    return f"{TOPIC_LABELS[topic]}.canvas"


def canvas_builder() -> tuple[list[dict[str, Any]], list[dict[str, Any]], Any, Any]:
    nodes: list[dict[str, Any]] = []
    edges: list[dict[str, Any]] = []
    counter = 0

    def add(node: dict[str, Any]) -> str:
        nonlocal counter
        counter += 1
        node["id"] = f"n{counter:04d}"
        nodes.append(node)
        return node["id"]

    def edge(from_id: str, to_id: str, label: str | None = None) -> None:
        item: dict[str, Any] = {"id": f"e{len(edges) + 1:04d}", "fromNode": from_id, "toNode": to_id}
        if label:
            item["label"] = label
        edges.append(item)

    return nodes, edges, add, edge


def wrapped_height(text: str, width: int = 340) -> int:
    chars_per_line = max(24, width // 8)
    return max(56, 22 * math.ceil(len(text) / chars_per_line) + 14)


def entity_homes(topic_data: dict[str, Any], entities: list[dict[str, Any]]) -> dict[str, tuple[str, str, str | None]]:
    """Select one deterministic detail-canvas home for every multi-pointer entity."""
    memberships: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for topic, data in topic_data.items():
        for cluster in data["clusters"]:
            for name in cluster["entities"]:
                memberships[name].append((topic, cluster["name"]))
    homes: dict[str, tuple[str, str, str | None]] = {}
    for entity in sorted(entities, key=lambda item: str(item["canonical"]).casefold()):
        if int(entity.get("pointer_count", 0)) < 2:
            continue
        canonical = str(entity["canonical"])
        primary = str(entity.get("primary_category") or "unsorted")
        topic = primary if primary in TOPIC_LABELS else "unsorted"
        candidates = sorted({cluster for candidate_topic, cluster in memberships.get(canonical, []) if candidate_topic == topic}, key=str.casefold)
        if int(entity.get("collection_pointer_count", 0)) == 0:
            homes[canonical] = (topic, "Shared by direct message", None)
        elif len(candidates) == 1:
            homes[canonical] = (topic, "cluster", candidates[0])
        else:
            homes[canonical] = (topic, "Cross-category", None)
    return homes


def cluster_biggest_entities(cluster: dict[str, Any], by_name: dict[str, dict[str, Any]]) -> str:
    names = sorted(cluster["entities"], key=lambda name: (-int(by_name[name].get("pointer_count", 0)), name.casefold()))[:3]
    return ", ".join(names) if names else "No named entities"


def overview_canvas(topic_data: dict[str, Any], entities: list[dict[str, Any]]) -> dict[str, Any]:
    """Legible category overview: ten cards plus a single preview row."""
    nodes, edges, add, _edge = canvas_builder()
    add({"type": "file", "file": f"{VAULT_ROOT}/00 - Saved AI Posts Corpus Index.md", "x": 20, "y": 20, "width": 420, "height": 300})
    add({"type": "file", "file": f"{VAULT_ROOT}/Comparisons/Cross-category comparison.md", "x": 500, "y": 20, "width": 420, "height": 300})
    for index, topic in enumerate(TOPIC_LABELS):
        column, row = index % 5, index // 5
        x, y = 20 + column * 460, 400 + row * 340
        category = topic_data[topic]
        top_entities = sorted(category["entities"], key=lambda item: (-int(item.get("pointer_count", 0)), str(item["canonical"]).casefold()))[:5]
        text_lines = [
            f"# {TOPIC_LABELS[topic]}",
            f"Posts: {len(category['records'])}",
            f"Entities: {len(category['entities'])}",
            "",
            "Top entities:",
        ]
        text_lines.extend(f"- {entity_link(entity, {str(item['canonical']): entity_filename_map(entities)[0][str(item['canonical'])] for item in entities})}" for entity in top_entities)
        text_lines.extend([
            "",
            f"{vault_link('Comparisons/' + slug(TOPIC_LABELS[topic]) + ' — comparison.md', 'Comparison note')}",
            f"{vault_link('Canvases/' + canvas_filename(topic), 'Detail canvas')}",
        ])
        add({"type": "text", "text": "\n".join(text_lines), "x": x, "y": y, "width": 360, "height": 240, "color": str(index % 6 + 1)})
    return {"nodes": nodes, "edges": edges}


def detail_canvas(topic: str, data: dict[str, Any], entities: list[dict[str, Any]], filenames: dict[str, str], homes: dict[str, tuple[str, str, str | None]]) -> dict[str, Any]:
    """Lay out only this category's entities as square-ish cluster groups."""
    nodes, edges, add, _edge = canvas_builder()
    add({"type": "file", "file": f"{VAULT_ROOT}/Comparisons/{slug(TOPIC_LABELS[topic])} — comparison.md", "x": 20, "y": 20, "width": 420, "height": 300})
    category_record_ids = set(data["record_ids"])
    all_by_name = {
        str(entity["canonical"]): entity
        for entity in entities
        if any(
            pointer.get("source") == "collection"
            and str(pointer.get("stable_id")) in category_record_ids
            for pointer in entity.get("pointers", [])
        )
    }
    groups: list[tuple[str, list[str]]] = []
    clustered: set[str] = set()
    assigned_to_cluster: set[str] = set()
    for cluster in data["clusters"]:
        candidate_names = {
            str(name) for name in cluster.get("entities", []) if str(name) in all_by_name
        }
        clustered.update(candidate_names)
        names = sorted(
            candidate_names - assigned_to_cluster,
            key=lambda name: (-int(all_by_name[name].get("pointer_count", 0)), name.casefold()),
        )
        assigned_to_cluster.update(names)
        if names:
            groups.append((f"{cluster['name']} ({len(cluster['post_ids'])} posts)", names))
    other = sorted(set(all_by_name) - clustered, key=lambda name: (-int(all_by_name[name].get("pointer_count", 0)), name.casefold()))
    if other:
        groups.append(("Other entities", other))
    card_width, card_height, card_gap = 260, 90, 40
    group_padding, label_clear, group_gap = 60, 50, 80
    group_specs: list[tuple[str, list[str], int, int, int]] = []
    for label, names in groups:
        card_columns = min(6, max(1, math.ceil(math.sqrt(len(names)))))
        rows = max(1, math.ceil(len(names) / card_columns))
        width = group_padding * 2 + card_columns * card_width + (card_columns - 1) * card_gap
        height = label_clear + group_padding + rows * card_height + (rows - 1) * card_gap + group_padding
        group_specs.append((label, names, width, height, card_columns))
    row_group_columns = 2
    column_widths = [
        max((spec[2] for index, spec in enumerate(group_specs) if index % row_group_columns == column), default=0)
        for column in range(row_group_columns)
    ]
    row_heights = [
        max((spec[3] for index, spec in enumerate(group_specs) if index // row_group_columns == row), default=0)
        for row in range(math.ceil(len(group_specs) / row_group_columns))
    ]
    specs: list[tuple[int, int, str, list[str], int, int, int]] = []
    for index, (label, names, width, height, card_columns) in enumerate(group_specs):
        row, column = divmod(index, row_group_columns)
        x = 20 + sum(column_widths[:column]) + group_gap * column
        y = 400 + sum(row_heights[:row]) + group_gap * row
        specs.append((x, y, label, names, width, height, card_columns))
    category_color = str(list(TOPIC_LABELS).index(topic) % 6 + 1)
    for x, y, label, names, width, height, card_columns in specs:
        add({"type": "group", "label": label, "x": x, "y": y, "width": width, "height": height, "color": category_color})
        for index, canonical in enumerate(names):
            column, row = index % card_columns, index // card_columns
            entity = all_by_name[canonical]
            posts = category_pointer_count(entity, topic, category_record_ids)
            text = f"{vault_link('Entities/' + filenames[canonical], canonical)}\n{posts} posts"
            add({"type": "text", "text": text, "x": x + group_padding + column * (card_width + card_gap), "y": y + label_clear + group_padding + row * (card_height + card_gap), "width": card_width, "height": card_height, "color": category_color})
    return {"nodes": nodes, "edges": edges}


def rect(node: dict[str, Any]) -> tuple[int, int, int, int]:
    x, y = int(node.get("x", 0)), int(node.get("y", 0))
    return x, y, x + int(node.get("width", 0)), y + int(node.get("height", 0))


def canvas_violations(canvas: dict[str, Any]) -> tuple[int, int]:
    nodes = canvas["nodes"]
    overlap = 0
    for i, left in enumerate(nodes):
        for right in nodes[i + 1 :]:
            a, b = rect(left), rect(right)
            intersects = max(a[0], b[0]) < min(a[2], b[2]) and max(a[1], b[1]) < min(a[3], b[3])
            contains = (a[0] <= b[0] and a[1] <= b[1] and a[2] >= b[2] and a[3] >= b[3]) or (b[0] <= a[0] and b[1] <= a[1] and b[2] >= a[2] and b[3] >= a[3])
            if intersects and not contains:
                overlap += 1
    groups = [n for n in nodes if n.get("type") == "group"]
    outside = 0
    first_group_y = min((int(group.get("y", 0)) for group in groups), default=0)
    for node in nodes:
        if node.get("type") == "group":
            continue
        x1, y1, x2, y2 = rect(node)
        contained = any(gx1 <= x1 and gy1 <= y1 and gx2 >= x2 and gy2 >= y2 for gx1, gy1, gx2, gy2 in (rect(g) for g in groups))
        root_header = y2 <= first_group_y
        if not contained and not root_header:
            outside += 1
    return overlap, outside


def validate_inputs(topic_docs: dict[str, dict[str, Any]], entities: list[dict[str, Any]], readings: dict[str, dict[str, Any]], records: dict[str, dict[str, Any]]) -> None:
    if set(topic_docs) != set(TOPIC_LABELS):
        raise RuntimeError(f"category files mismatch: {sorted(topic_docs)}")
    if len(readings) != 46:
        raise RuntimeError(f"expected 46 entity readings, found {len(readings)}")
    multi = {e["canonical"] for e in entities if int(e.get("pointer_count", 0)) >= 2}
    if set(readings) != multi:
        raise RuntimeError("entity-readings-v1 does not exactly cover the multi-pointer entity set")
    seen: set[str] = set()
    for topic, doc in topic_docs.items():
        if doc.get("topic") != topic:
            raise RuntimeError(f"topic mismatch in {topic}")
        if not doc.get("headline") or not isinstance(doc.get("clusters"), list):
            raise RuntimeError(f"invalid shape in {topic}")
        ids = [str(pid) for cluster in doc["clusters"] for pid in cluster.get("post_ids", [])]
        if len(ids) != len(set(ids)):
            raise RuntimeError(f"duplicate post ids in {topic}")
        if any(pid not in records for pid in ids):
            raise RuntimeError(f"unknown post id in {topic}")
        seen.update(ids)
    if len(seen) != 192:
        raise RuntimeError(f"category files cover {len(seen)} posts, expected 192")
    for doc in topic_docs.values():
        for cluster in doc["clusters"]:
            for entry in [cluster["summary"], *cluster["comparison"]]:
                for cite in entry.get("cites", []):
                    if str(cite) not in records:
                        raise RuntimeError(f"unknown citation {cite}")
        for entry in [*doc.get("thin_evidence", []), *doc.get("try_first", [])]:
            for cite in entry.get("cites", []):
                if str(cite) not in records:
                    raise RuntimeError(f"unknown citation {cite}")


def build() -> dict[str, Any]:
    entity_doc = read_json(ENTITY_JSON)
    entities = entity_doc["entities"]
    readings = {row["canonical"]: row for row in read_json(READINGS_JSON)["entities"]}
    topic_overlay = {row["stable_id"]: row["primary_topic"] for row in read_json(TOPIC_JSON)}
    records_list = [row for row in read_json(CATALOG_JSON)["records"] if row.get("collection_membership") == "confirmed"]
    records = {row["stable_id"]: row for row in records_list}
    if len(records) != 192 or set(topic_overlay) != set(records):
        raise RuntimeError("confirmed records and topic overlay must both cover exactly 192 records")
    topic_docs = {p.stem: read_json(p) for p in COMPARISONS.glob("*.json") if p.name != "_cross-category.json"}
    validate_inputs(topic_docs, entities, readings, records)
    by_name = {e["canonical"]: e for e in entities}
    filenames, sanitised = entity_filename_map(entities)
    entity_dir, comparison_dir = PUBLICATION / "Entities", PUBLICATION / "Comparisons"
    entity_dir.mkdir(parents=True, exist_ok=True)
    comparison_dir.mkdir(parents=True, exist_ok=True)
    for path in entity_dir.glob("*.md"):
        try:
            path.unlink()
        except PermissionError:
            pass
    for path in comparison_dir.glob("*.md"):
        try:
            path.unlink()
        except PermissionError:
            pass
    multi = [e for e in entities if int(e.get("pointer_count", 0)) >= 2]
    for entity in sorted(entities, key=lambda e: str(e["canonical"]).casefold()):
        target = entity_dir / filenames[entity["canonical"]]
        try:
            target.write_text(entity_note(entity, readings.get(entity["canonical"], {}), records, filenames, sanitised), encoding="utf-8", newline="\n")
        except PermissionError:
            if not target.exists():
                raise
    rewrite_entity_links(filenames)
    append_source_entity_links(entities, records, filenames)
    topic_data: dict[str, Any] = {}
    for topic in TOPIC_LABELS:
        doc = topic_docs[topic]
        comparison_ids = {str(pid) for cluster in doc["clusters"] for pid in cluster["post_ids"]}
        category_record_ids = {stable_id for stable_id, assigned_topic in topic_overlay.items() if assigned_topic == topic}
        if comparison_ids != category_record_ids:
            raise RuntimeError(f"comparison post_ids do not match primary_topic assignment for {topic}")
        comparison_ents = topic_entities(doc, by_name)
        ents = [
            entity for entity in entities
            if any(
                pointer.get("source") == "collection"
                and str(pointer.get("stable_id")) in category_record_ids
                for pointer in entity.get("pointers", [])
            )
        ]
        topic_data[topic] = {"records": [records[sid] for sid in sorted(category_record_ids)], "record_ids": category_record_ids, "entities": ents, "clusters": doc["clusters"], "doc": doc}
        note, _ = comparison_note(topic, doc, records, comparison_ents, filenames)
        target = comparison_dir / f"{slug(TOPIC_LABELS[topic])} — comparison.md"
        try:
            target.write_text(note, encoding="utf-8", newline="\n")
        except PermissionError:
            if not target.exists():
                raise
    cross_doc = read_json(CROSS_JSON)
    for item in cross_doc.get("spanning_entities", []) + cross_doc.get("priority_clusters", []):
        if not item.get("text") or not item.get("cites"):
            raise RuntimeError("cross-category entries require text and cites")
        for cite in item["cites"]:
            if str(cite) not in records:
                raise RuntimeError(f"unknown cross-category citation {cite}")
    cross_target = comparison_dir / "Cross-category comparison.md"
    try:
        cross_target.write_text(cross_category_note(cross_doc, topic_data, records, by_name, filenames), encoding="utf-8", newline="\n")
    except PermissionError:
        if not cross_target.exists():
            raise
    canvas = overview_canvas(topic_data, entities)
    canvas_target = PUBLICATION / "Saved AI Posts.canvas"
    try:
        canvas_target.write_text(json.dumps(canvas, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    except PermissionError:
        if not canvas_target.exists():
            raise
    canvases_dir = PUBLICATION / "Canvases"
    canvases_dir.mkdir(parents=True, exist_ok=True)
    detail_canvases: dict[str, dict[str, Any]] = {}
    for topic in TOPIC_LABELS:
        detail = detail_canvas(topic, topic_data[topic], entities, filenames, {})
        detail_canvases[topic] = detail
        target = canvases_dir / canvas_filename(topic)
        try:
            target.write_text(json.dumps(detail, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
        except PermissionError:
            if not target.exists():
                raise
    write_json(COMPARISON_INDEX, {
        "schema_version": "comparisons-v1", "updated": "2026-09-21", "entity_file_count": len(entities),
        "comparison_file_count": 11, "topic_count": len(TOPIC_LABELS), "cluster_count": sum(len(topic_data[t]["clusters"]) for t in TOPIC_LABELS),
        "multi_pointer_entity_count": len(multi), "entity_files": sorted(filenames[e["canonical"]] for e in entities),
        "comparison_files": sorted(p.name for p in comparison_dir.glob("*.md")),
        "topic_counts": {t: {"posts": len(topic_data[t]["records"]), "entities": len(topic_data[t]["entities"]), "clusters": len(topic_data[t]["clusters"])} for t in TOPIC_LABELS},
    })
    entity_links = [(f"Entities/{filenames[e['canonical']]}", str(e["canonical"])) for e in sorted(entities, key=lambda e: str(e["canonical"]).casefold())]
    comparison_links = [(f"Comparisons/{path.name}", path.stem) for path in sorted(comparison_dir.glob("*.md")) if path.name != "README.md"]
    (entity_dir / "Entity map.md").write_text(entity_map_note(entities, filenames), encoding="utf-8", newline="\n")
    (entity_dir / "README.md").write_text(folder_readme("Saved AI Posts — Entities index", "This folder holds one note per classified entity and a category/kind map.", [("Entities/Entity map.md", "Entity map")]), encoding="utf-8", newline="\n")
    (comparison_dir / "README.md").write_text(folder_readme("Saved AI Posts — Comparisons index", "This folder holds one comparison note per topic plus the cross-category synthesis.", comparison_links), encoding="utf-8", newline="\n")
    ensure_agent_note_tags()
    ensure_corpus_index_links()
    overlap, outside = canvas_violations(canvas)
    detail_checks = {topic: canvas_violations(detail) for topic, detail in detail_canvases.items()}
    return {"entity_notes": len(entity_links), "comparison_notes": len(comparison_links), "canvas_nodes": len(canvas["nodes"]), "canvas_edges": len(canvas["edges"]), "canvas_groups": sum(1 for n in canvas["nodes"] if n.get("type") == "group"), "canvas_overlap": overlap, "canvas_outside": outside, "detail_canvas_count": len(detail_canvases), "detail_canvas_violations": {topic: {"overlap": pair[0], "outside": pair[1]} for topic, pair in detail_checks.items()}, "multi_pointer_entities": len(multi), "clusters": sum(len(topic_data[t]["clusters"]) for t in TOPIC_LABELS), "topics": len(TOPIC_LABELS)}


if __name__ == "__main__":
    print(json.dumps(build(), ensure_ascii=False, sort_keys=True))
