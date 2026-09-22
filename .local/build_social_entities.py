"""Render the analysed entity, comparison, and canvas layer for Saved AI Posts."""
from __future__ import annotations

import hashlib
import itertools
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
CARD_LINES_JSON = CLASSIFICATION / "card-lines-v1.json"

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


# Judgement data: these lines are intentionally short so they remain useful at fit-to-screen zoom.
CATEGORY_LINES = {
    "agents-and-coding": "Build reliable agents around durable context, explicit tool boundaries, and small tests.",
    "ai-news": "A source-check queue for launches, models, and video-generation claims.",
    "business": "Turn capability stories into offers only after evidence, costs, and controls are visible.",
    "cad-and-3d": "Prompted code is becoming an interactive 3D production surface; reproduce one scene first.",
    "design-tools": "Named prompts, handoffs, and assets make AI design workflows reproducible.",
    "hardware": "AI becomes tangible through new interfaces, dedicated machines, and physical safety boundaries.",
    "research": "Prefer inspectable artifacts—certificates, editable code, harnesses—over opaque outputs.",
    "security": "Automation becomes risky at irreversible, adversarial, or privacy-sensitive control boundaries.",
    "workflows-and-productivity": "Reliability starts upstream: plans, architecture constraints, context, and visible handoffs.",
    "unsorted": "Preserved uncertainty: a queue of unavailable guides and contextless references.",
}

CLUSTER_LINES = {
    ("agents-and-coding", "Memory, loops, and agent coordination"): "Treat context as engineered state: memory tiers, handoffs, loops, and measured continuation.",
    ("agents-and-coding", "Tool boundaries and multimodal controls"): "Choose the smallest agent interface: CLI, MCP, visual surface, or message thread.",
    ("agents-and-coding", "Model and benchmark claims"): "Separate named tests and workflows from unlinked performance claims.",
    ("agents-and-coding", "Builder resources and open repositories"): "Inspect the artifact first; distinguish a usable repository from a promotional promise.",
    ("agents-and-coding", "Gated or underspecified recommendations"): "Treat comment gates and blurred names as leads, not implementation evidence.",
    ("ai-news", "Roundups that compress many claims"): "Roundups are triage queues: verify each headline before carrying it forward.",
    ("ai-news", "Video-generation launches and performance claims"): "Verify video-model news with production tests, throughput, and terms.",
    ("ai-news", "Unnamed releases and sponsored serial teasers"): "Missing names and sponsorship make these saves follow-up prompts, not findings.",
    ("business", "Service offers and monetization claims"): "Service promises become useful only when delivery, price, and proof are explicit.",
    ("business", "Trading experiments and agentic finance"): "Trading demos need controls and a reproducible record before they become advice.",
    ("business", "Growth tactics and access-risk claims"): "Growth tactics sit beside access and provenance risks that need checking.",
    ("business", "Unresolved entrepreneurship signal"): "A lone signal is a prompt for research, not a business case.",
    ("cad-and-3d", "Early-release 3D build showcases"): "Early showcases are compelling demonstrations, but their release claims need reproduction.",
    ("cad-and-3d", "Code-to-3D production claims"): "Code, photos, and drawings can become 3D outputs; test one narrow path.",
    ("cad-and-3d", "3D local-file workspace concept"): "A local-file workspace idea is promising, but its boundary is still conceptual.",
    ("design-tools", "Generative image and motion production"): "Visual results are chains of inputs and handoffs, not magic prompts.",
    ("design-tools", "Agent-readable design and interface generation"): "Make design intent legible so prompts, files, and components survive the handoff.",
    ("design-tools", "Reusable interface assets and design methods"): "Reusable assets turn taste into a repeatable production method.",
    ("design-tools", "Reference, evaluation, and exploratory design"): "References and evaluations separate a promising direction from a finished method.",
    ("design-tools", "Comment-gated and promotional design claims"): "Gates hide inputs, outputs, and rules needed to reproduce claims.",
    ("hardware", "Embodied and ambient interfaces"): "Sensors and realtime models make interaction tangible, but prototypes need boundaries.",
    ("hardware", "Dedicated computers for agents"): "Dedicated machines make agent capacity concrete while concentrating cost and control.",
    ("hardware", "Physical-device and credential boundaries"): "Agent safety is a blast-radius problem: credentials, devices, approvals, and reversibility.",
    ("hardware", "Modular desk controls and sponsored accessories"): "Desk hardware is a workflow surface whose sponsorship claims need independent proof.",
    ("research", "Model-behavior studies"): "Behavior studies need inspectable tasks, comparisons, and failure modes.",
    ("research", "Formal reasoning reports"): "Formal reports offer useful constraints when their certificates and assumptions remain visible.",
    ("research", "Experimental AI architectures"): "Inspect the boundary: executable harnesses, editable artifacts, and transfer mechanisms.",
    ("research", "Applied AI demonstrations"): "Applied demos need repeatable workflows and visible inputs to count as evidence.",
    ("research", "Unpublished efficiency promise"): "An efficiency promise without a paper or artifact stays unresolved.",
    ("security", "Self-hosted OSINT dashboards"): "Named data tools are inspectable; intelligence claims still need provenance.",
    ("security", "Authorization, ranking, and high-consequence control"): "Never let agent access outrun confirmation, reversibility, and accountable human control.",
    ("security", "Privacy maintenance and generic security warnings"): "Privacy work needs specific data paths, deletion evidence, and a threat model.",
    ("unsorted", "Keyword-gated offers"): "Keyword gates preserve a lead while withholding the guide, repository, or method.",
    ("unsorted", "Contextless teasers and labels"): "Contextless labels are useful as reminders, not as evidence.",
    ("workflows-and-productivity", "Plan-first execution and decision guardrails"): "Use stronger reasoning to resolve ambiguity, then constrain execution with recorded intent.",
    ("workflows-and-productivity", "Context graphs and organizational memory"): "The durable product is connected, contradiction-aware context—not a larger swarm.",
    ("workflows-and-productivity", "Client service operating systems"): "Trust comes from visible delivery artifacts that prevent scope and communication drift.",
    ("workflows-and-productivity", "Promoted tools and underspecified workflows"): "Promoted tools need a concrete workflow, owner, and failure path before adoption.",
}

RELATION_OVERRIDES = {
    frozenset({"agents-and-coding|Memory, loops, and agent coordination", "workflows-and-productivity|Context graphs and organizational memory"}): "Context becomes infrastructure",
    frozenset({"agents-and-coding|Tool boundaries and multimodal controls", "design-tools|Agent-readable design and interface generation"}): "MCP carries design intent into execution",
    frozenset({"agents-and-coding|Tool boundaries and multimodal controls", "research|Experimental AI architectures"}): "MCP exposes the execution boundary",
    frozenset({"ai-news|Video-generation launches and performance claims", "design-tools|Generative image and motion production"}): "Models become production workflows",
    frozenset({"agents-and-coding|Model and benchmark claims", "cad-and-3d|Early-release 3D build showcases"}): "Model claims meet build evidence",
    frozenset({"cad-and-3d|Early-release 3D build showcases", "design-tools|Agent-readable design and interface generation"}): "Figma connects 3D and interface handoffs",
    frozenset({"agents-and-coding|Memory, loops, and agent coordination", "security|Authorization, ranking, and high-consequence control"}): "Agent autonomy needs reversibility",
    frozenset({"security|Authorization, ranking, and high-consequence control", "workflows-and-productivity|Plan-first execution and decision guardrails"}): "Controls come before action",
    frozenset({"hardware|Physical-device and credential boundaries", "security|Authorization, ranking, and high-consequence control"}): "Blast radius needs explicit limits",
    frozenset({"design-tools|Agent-readable design and interface generation", "workflows-and-productivity|Client service operating systems"}): "Visible artifacts make handoffs accountable",
    frozenset({"research|Experimental AI architectures", "security|Self-hosted OSINT dashboards"}): "Inspect sources and mechanisms",
}


def _relation_token(topic: str, cluster_name: str) -> str:
    words = re.findall(r"[A-Za-z0-9]+", cluster_name.lower())
    return f"{topic}-{'-'.join(words[:3])}"


def build_card_lines(topic_data: dict[str, Any]) -> dict[str, Any]:
    relations: list[dict[str, Any]] = []
    clusters: list[tuple[str, str, dict[str, Any]]] = []
    for topic in TOPIC_LABELS:
        for cluster in topic_data[topic]["clusters"]:
            clusters.append((topic, str(cluster["name"]), cluster))
    for (topic_a, name_a, cluster_a), (topic_b, name_b, cluster_b) in itertools.combinations(clusters, 2):
        shared_entities = sorted(set(cluster_a.get("entities", [])) & set(cluster_b.get("entities", [])), key=str.casefold)
        shared_posts = sorted(set(cluster_a.get("post_ids", [])) & set(cluster_b.get("post_ids", [])))
        if not shared_entities and not shared_posts:
            continue
        key = frozenset({f"{topic_a}|{name_a}", f"{topic_b}|{name_b}"})
        line = RELATION_OVERRIDES.get(key)
        if not line:
            # No hand-written line for this pair: label with the shared data itself, never composed prose.
            line = "shared: " + ", ".join(shared_entities[:3]) if shared_entities else f"{len(shared_posts)} shared posts"
        relations.append({"a": f"{topic_a}|{name_a}", "b": f"{topic_b}|{name_b}", "shared_entities": shared_entities, "shared_posts": shared_posts, "line": line, "line_kind": "hand-written" if key in RELATION_OVERRIDES else "data"})
    return {
        "schema_version": "card-lines-v1",
        "categories": {topic: {"line": CATEGORY_LINES[topic]} for topic in TOPIC_LABELS},
        "clusters": {topic: {str(cluster["name"]): {"line": CLUSTER_LINES[(topic, str(cluster["name"]))]} for cluster in topic_data[topic]["clusters"]} for topic in TOPIC_LABELS},
        "relations": relations,
    }


def _force_layout(keys: list[str], sets: dict[str, set[str]], width: float, height: float, *, seed: int = 17) -> dict[str, tuple[float, float]]:
    """Small deterministic force layout; shared-set overlap pulls nodes together."""
    if not keys:
        return {}
    columns = max(1, math.ceil(math.sqrt(len(keys))))
    rows = math.ceil(len(keys) / columns)
    points: dict[str, list[float]] = {}
    for index, key in enumerate(keys):
        column, row = divmod(index, columns)
        points[key] = [(column + 0.5 + math.sin((index + 1) * (seed + 3)) * 0.08) / columns * width, (row + 0.5 + math.cos((index + 1) * (seed + 5)) * 0.08) / rows * height]
    for _ in range(180):
        forces = {key: [0.0, 0.0] for key in keys}
        for left_index, left_key in enumerate(keys):
            for right_key in keys[left_index + 1 :]:
                dx = points[right_key][0] - points[left_key][0]
                dy = points[right_key][1] - points[left_key][1]
                distance = max(1.0, math.hypot(dx, dy))
                overlap = len(sets[left_key] & sets[right_key]) / max(1, len(sets[left_key] | sets[right_key]))
                desired = max(180.0, min(width, height) * (0.66 - 0.42 * overlap))
                spring = (distance - desired) * 0.004
                repel = 12000.0 / (distance * distance)
                ux, uy = dx / distance, dy / distance
                fx, fy = ux * (spring + repel), uy * (spring + repel)
                forces[left_key][0] -= fx; forces[left_key][1] -= fy
                forces[right_key][0] += fx; forces[right_key][1] += fy
        for key in keys:
            points[key][0] = min(width - 20, max(20, points[key][0] + forces[key][0]))
            points[key][1] = min(height - 20, max(20, points[key][1] + forces[key][1]))
    min_x = min(point[0] for point in points.values()); max_x = max(point[0] for point in points.values())
    min_y = min(point[1] for point in points.values()); max_y = max(point[1] for point in points.values())
    span_x, span_y = max(1.0, max_x - min_x), max(1.0, max_y - min_y)
    return {key: (40 + (point[0] - min_x) / span_x * max(1.0, width - 80), 40 + (point[1] - min_y) / span_y * max(1.0, height - 80)) for key, point in points.items()}


def _resolve_rect_overlaps(positions: dict[str, tuple[float, float]], sizes: dict[str, tuple[float, float]], width: float, height: float, rounds: int = 80) -> dict[str, tuple[float, float]]:
    result = {key: [float(value[0]), float(value[1])] for key, value in positions.items()}
    keys = list(result)
    for _ in range(rounds):
        moved = False
        for index, left_key in enumerate(keys):
            for right_key in keys[index + 1 :]:
                lx, ly = result[left_key]; lw, lh = sizes[left_key]
                rx, ry = result[right_key]; rw, rh = sizes[right_key]
                overlap_x = min(lx + lw, rx + rw) - max(lx, rx)
                overlap_y = min(ly + lh, ry + rh) - max(ly, ry)
                if overlap_x <= 0 or overlap_y <= 0:
                    continue
                moved = True
                if overlap_x < overlap_y:
                    shift = overlap_x / 2 + 8
                    if lx <= rx: result[left_key][0] -= shift; result[right_key][0] += shift
                    else: result[left_key][0] += shift; result[right_key][0] -= shift
                else:
                    shift = overlap_y / 2 + 8
                    if ly <= ry: result[left_key][1] -= shift; result[right_key][1] += shift
                    else: result[left_key][1] += shift; result[right_key][1] -= shift
        for key, (w, h) in sizes.items():
            result[key][0] = min(width - w - 10, max(10, result[key][0]))
            result[key][1] = min(height - h - 10, max(10, result[key][1]))
        if not moved:
            break
    return {key: (round(value[0]), round(value[1])) for key, value in result.items()}


def _facing_sides(from_node: dict[str, Any], to_node: dict[str, Any]) -> tuple[str, str]:
    from_centre = (float(from_node.get("x", 0)) + float(from_node.get("width", 0)) / 2, float(from_node.get("y", 0)) + float(from_node.get("height", 0)) / 2)
    to_centre = (float(to_node.get("x", 0)) + float(to_node.get("width", 0)) / 2, float(to_node.get("y", 0)) + float(to_node.get("height", 0)) / 2)
    dx, dy = to_centre[0] - from_centre[0], to_centre[1] - from_centre[1]
    if abs(dx) >= abs(dy):
        return ("right", "left") if dx >= 0 else ("left", "right")
    return ("bottom", "top") if dy >= 0 else ("top", "bottom")


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

    def edge(from_id: str, to_id: str, label: str | None = None, from_side: str | None = None, to_side: str | None = None) -> None:
        node_by_id = {node["id"]: node for node in nodes}
        computed_from, computed_to = _facing_sides(node_by_id[from_id], node_by_id[to_id])
        item: dict[str, Any] = {"id": f"e{len(edges) + 1:04d}", "fromNode": from_id, "toNode": to_id}
        item["fromSide"] = from_side or computed_from
        item["toSide"] = to_side or computed_to
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


def _jaccard(left: set[str], right: set[str]) -> float:
    union = left | right
    return len(left & right) / len(union) if union else 0.0


def _greedy_ring_order(keys: list[str], sets: dict[str, set[str]]) -> list[str]:
    if len(keys) < 2:
        return list(keys)
    start = max(keys, key=lambda key: (sum(_jaccard(sets[key], sets[other]) for other in keys if other != key), key.casefold()))
    ordered = [start]
    remaining = set(keys) - {start}
    while remaining:
        previous = ordered[-1]
        next_key = max(remaining, key=lambda key: (_jaccard(sets[previous], sets[key]), key.casefold()))
        ordered.append(next_key)
        remaining.remove(next_key)
    return ordered


def overview_canvas(topic_data: dict[str, Any], entities: list[dict[str, Any]], card_lines: dict[str, Any]) -> dict[str, Any]:
    """Hub-and-ring category map whose distance and edges encode meaningful relatedness."""
    nodes, edges, add, edge = canvas_builder()
    add({"type": "file", "file": f"{VAULT_ROOT}/00 - Saved AI Posts Corpus Index.md", "x": 1660, "y": 20, "width": 420, "height": 300})
    add({"type": "file", "file": f"{VAULT_ROOT}/Comparisons/Cross-category comparison.md", "x": 2110, "y": 20, "width": 430, "height": 300})
    keys = list(TOPIC_LABELS)
    entity_sets = {topic: {str(entity["canonical"]) for entity in topic_data[topic]["entities"]} for topic in keys}
    ubiquitous = sorted((name for name in set().union(*entity_sets.values()) if sum(name in values for values in entity_sets.values()) >= 5), key=str.casefold)
    meaningful_sets = {topic: values - set(ubiquitous) for topic, values in entity_sets.items()}
    centre_topic = max(keys, key=lambda key: (len(topic_data[key]["records"]), -keys.index(key)))
    ring_topics = _greedy_ring_order([key for key in keys if key != centre_topic], meaningful_sets)
    sizes = {topic: (min(520, max(380, 330 + len(topic_data[topic]["records"]) * 2)), 184) for topic in keys}
    centre = (1300.0, 1000.0)
    positions: dict[str, tuple[float, float]] = {centre_topic: (centre[0] - sizes[centre_topic][0] / 2, centre[1] - sizes[centre_topic][1] / 2)}
    for index, topic in enumerate(ring_topics):
        similarity = _jaccard(meaningful_sets[centre_topic], meaningful_sets[topic])
        radius = min(780.0, 700.0 + min(400.0, max(0.0, 1.0 - similarity) * 400.0))
        angle = -math.pi / 2 + index * (2 * math.pi / max(1, len(ring_topics)))
        cx, cy = centre[0] + radius * math.cos(angle), centre[1] + radius * 0.70 * math.sin(angle)
        width, height = sizes[topic]
        positions[topic] = (cx - width / 2, cy - height / 2)
    positions = _resolve_rect_overlaps(positions, sizes, 2600, 1800, rounds=60)
    legend_text = "\n".join([
        "## Canvas legend",
        "centre = largest category",
        "distance from centre = how little it shares with the centre",
        "neighbours on the ring = most related",
        "edges = named shared tools",
        "Everywhere: " + (", ".join(ubiquitous) if ubiquitous else "none"),
    ])
    add({"type": "text", "text": legend_text, "x": 20, "y": 20, "width": 900, "height": 250})
    node_ids: dict[str, str] = {}
    for index, topic in enumerate(keys):
        category = topic_data[topic]
        width, height = sizes[topic]
        text_lines = [
            f"## {TOPIC_LABELS[topic]}", card_lines["categories"][topic]["line"],
            f"{len(category['records'])} posts · {len(category['entities'])} entities",
            f"{vault_link('Comparisons/' + slug(TOPIC_LABELS[topic]) + ' — comparison.md', 'Comparison note')}",
            f"{vault_link('Canvases/' + canvas_filename(topic), 'Detail canvas')}",
        ]
        x, y = positions[topic]
        node_ids[topic] = add({"type": "text", "text": "\n".join(text_lines), "x": x, "y": y, "width": width, "height": height, "color": str(index % 6 + 1)})
    candidates: list[tuple[int, float, str, str, list[str]]] = []
    for left_index, left_topic in enumerate(keys):
        for right_topic in keys[left_index + 1 :]:
            shared = sorted(meaningful_sets[left_topic] & meaningful_sets[right_topic], key=str.casefold)
            if len(shared) >= 2:
                candidates.append((len(shared), _jaccard(meaningful_sets[left_topic], meaningful_sets[right_topic]), left_topic, right_topic, shared))
    candidates.sort(key=lambda item: (-item[0], -item[1], item[2], item[3]))
    degrees: defaultdict[str, int] = defaultdict(int)
    for _count, _similarity, left_topic, right_topic, shared in candidates:
        if degrees[left_topic] >= 2 or degrees[right_topic] >= 2:
            continue
        degrees[left_topic] += 1
        degrees[right_topic] += 1
        edge(node_ids[left_topic], node_ids[right_topic], "shared: " + ", ".join(shared[:3]))
    return {"nodes": nodes, "edges": edges}


def detail_canvas(topic: str, data: dict[str, Any], entities: list[dict[str, Any]], filenames: dict[str, str], homes: dict[str, tuple[str, str, str | None]], card_lines: dict[str, Any], topic_data: dict[str, Any]) -> dict[str, Any]:
    """Cluster map with summary-first groups and shared entity hubs between them."""
    nodes, edges, add, edge = canvas_builder()
    category_color = str(list(TOPIC_LABELS).index(topic) % 6 + 1)
    header_text = "\n".join([
        f"# {TOPIC_LABELS[topic]}", card_lines["categories"][topic]["line"],
        f"{len(data['records'])} posts · {len(data['entities'])} entities",
        f"{vault_link('Saved AI Posts.canvas', 'Back to overview canvas')}",
    ])
    add({"type": "text", "text": header_text, "x": 20, "y": 20, "width": 980, "height": 220, "color": category_color})
    add({"type": "file", "file": f"{VAULT_ROOT}/Comparisons/{slug(TOPIC_LABELS[topic])} — comparison.md", "x": 1040, "y": 20, "width": 420, "height": 300})
    category_record_ids = set(data["record_ids"])
    all_by_name = {
        str(entity["canonical"]): entity for entity in entities
        if any(pointer.get("source") == "collection" and str(pointer.get("stable_id")) in category_record_ids for pointer in entity.get("pointers", []))
    }
    memberships: dict[str, list[str]] = defaultdict(list)
    cluster_rows: list[dict[str, Any]] = []
    for cluster in data["clusters"]:
        name = str(cluster["name"])
        names = [str(item) for item in cluster.get("entities", []) if str(item) in all_by_name]
        for name_item in names:
            memberships[name_item].append(name)
        cluster_rows.append({"name": name, "posts": len(cluster.get("post_ids", [])), "names": names})
    shared_names = {name for name, cluster_names in memberships.items() if len(cluster_names) >= 2}
    clustered_names = set(memberships)
    other_names = sorted(set(all_by_name) - clustered_names, key=lambda name: (-int(all_by_name[name].get("pointer_count", 0)), name.casefold()))
    if other_names:
        cluster_rows.append({"name": "Other entities", "posts": 0, "names": other_names, "other": True})
    group_sizes: dict[str, tuple[int, int]] = {}
    group_names: dict[str, list[str]] = {}
    for row in cluster_rows:
        names = row["names"] if row.get("other") else [name for name in row["names"] if name not in shared_names]
        names = sorted(names, key=lambda name: (-int(all_by_name[name].get("pointer_count", 0)), name.casefold()))
        group_names[row["name"]] = names
        columns = min(6 if row.get("other") else 5, max(1, math.ceil(math.sqrt(max(1, len(names))))))
        rows = max(1, math.ceil(len(names) / columns))
        card_width = 200 if row.get("other") else 220
        card_height = 60 if row.get("other") else 84
        width = max(460, 48 + columns * 232)
        height = 24 + 24 + 100 + 12 + rows * card_height + (rows - 1) * 12 + 108
        group_sizes[row["name"]] = (width, height)
    group_keys = [row["name"] for row in cluster_rows]
    group_sets = {row["name"]: set(row["names"]) for row in cluster_rows}
    force_positions = _force_layout(group_keys, group_sets, 2940, 1600, seed=31)
    ordered_groups = sorted(group_keys, key=lambda name: (force_positions[name][1], force_positions[name][0]))
    column_widths = [max((group_sizes[name][0] for index, name in enumerate(ordered_groups) if index % 2 == column), default=0) for column in range(2)]
    row_heights = [max((group_sizes[name][1] for index, name in enumerate(ordered_groups) if index // 2 == row), default=0) for row in range(math.ceil(len(ordered_groups) / 2))]
    group_positions: dict[str, tuple[int, int]] = {}
    for index, name in enumerate(ordered_groups):
        row_index, column = divmod(index, 2)
        group_positions[name] = (20 + (column_widths[0] + 60 if column else 0), 340 + sum(row_heights[:row_index]) + row_index * 20)
    group_ids: dict[str, str] = {}
    for row in cluster_rows:
        label = row["name"]
        x, y = group_positions[label]
        width, height = group_sizes[label]
        group_ids[label] = add({"type": "group", "label": label, "x": x, "y": y, "width": width, "height": height, "color": category_color})
    entity_topics = {str(entity["canonical"]): [candidate for candidate in TOPIC_LABELS if str(entity["canonical"]) in {str(item["canonical"]) for item in topic_data[candidate]["entities"]}] for entity in entities}
    for row in cluster_rows:
        label = row["name"]
        x, y = group_positions[label]
        width, _height = group_sizes[label]
        names = group_names[label]
        summary_line = card_lines["clusters"].get(topic, {}).get(label, {}).get("line", "")
        add({"type": "text", "text": f"## {label}\n{summary_line}\n{row['posts']} posts", "x": x + 24, "y": y + 24, "width": max(420, width - 48), "height": 100, "color": category_color})
        columns = min(6 if row.get("other") else 5, max(1, math.ceil(math.sqrt(max(1, len(names))))))
        max_posts = max([category_pointer_count(all_by_name[name], topic, category_record_ids) for name in names] or [1])
        for index, canonical in enumerate(names):
            column, row_index = divmod(index, columns)
            entity = all_by_name[canonical]
            posts = category_pointer_count(entity, topic, category_record_ids)
            scale = math.sqrt(posts / max_posts) if max_posts else 1
            card_width = round(200 if row.get("other") else 200 + 20 * scale)
            card_height = round(60 if row.get("other") else 60 + 24 * scale)
            lines = [f"## {canonical}", f"{posts} post{'s' if posts != 1 else ''}"]
            other_topics = [candidate for candidate in entity_topics.get(canonical, []) if candidate != topic]
            if other_topics:
                lines.append("↗ also in: " + ", ".join(vault_link("Canvases/" + canvas_filename(candidate), TOPIC_LABELS[candidate]) for candidate in other_topics))
            add({"type": "text", "text": "\n".join(lines), "x": x + 24 + column * 232, "y": y + 144 + row_index * 96, "width": card_width, "height": card_height, "color": category_color})
    for index, canonical in enumerate(sorted(shared_names, key=str.casefold)):
        names = memberships[canonical]
        entity = all_by_name[canonical]
        posts = category_pointer_count(entity, topic, category_record_ids)
        lines = [f"## {canonical}", f"{posts} post{'s' if posts != 1 else ''}"]
        other_topics = [candidate for candidate in entity_topics.get(canonical, []) if candidate != topic]
        if other_topics:
            lines.append("↗ also in: " + ", ".join(vault_link("Canvases/" + canvas_filename(candidate), TOPIC_LABELS[candidate]) for candidate in other_topics))
        # Keep shared hubs in the clear strip between the header and groups.
        entity_id = add({"type": "text", "text": "\n".join(lines), "x": 1500 + (index % 6) * 230, "y": 245, "width": 220, "height": 90, "color": category_color})
        for cluster_name in names:
            edge(entity_id, group_ids[cluster_name], cluster_name)
    relation_lookup = {frozenset({item["a"], item["b"]}): item for item in card_lines.get("relations", [])}
    for left_index, left in enumerate(cluster_rows):
        if left.get("other"):
            continue
        for right in cluster_rows[left_index + 1 :]:
            if right.get("other"):
                continue
            relation = relation_lookup.get(frozenset({f"{topic}|{left['name']}", f"{topic}|{right['name']}"}))
            if relation:
                edge(group_ids[left["name"]], group_ids[right["name"]], relation["line"])
    return {"nodes": nodes, "edges": edges}


def detail_canvas(topic: str, data: dict[str, Any], entities: list[dict[str, Any]], filenames: dict[str, str], homes: dict[str, tuple[str, str, str | None]], card_lines: dict[str, Any], topic_data: dict[str, Any]) -> dict[str, Any]:
    """Shared-core and ring layout for one category's clusters."""
    nodes, edges, add, edge = canvas_builder()
    category_color = str(list(TOPIC_LABELS).index(topic) % 6 + 1)
    header_text = "\n".join([
        f"# {TOPIC_LABELS[topic]}", card_lines["categories"][topic]["line"],
        f"{len(data['records'])} posts · {len(data['entities'])} entities",
        f"{vault_link('Saved AI Posts.canvas', 'Back to overview canvas')}",
    ])
    add({"type": "text", "text": header_text, "x": 20, "y": 20, "width": 980, "height": 220, "color": category_color})
    add({"type": "file", "file": f"{VAULT_ROOT}/Comparisons/{slug(TOPIC_LABELS[topic])} — comparison.md", "x": 1040, "y": 20, "width": 420, "height": 300})
    category_record_ids = set(data["record_ids"])
    all_by_name = {str(entity["canonical"]): entity for entity in entities if any(pointer.get("source") == "collection" and str(pointer.get("stable_id")) in category_record_ids for pointer in entity.get("pointers", []))}
    memberships: dict[str, list[str]] = defaultdict(list)
    cluster_rows: list[dict[str, Any]] = []
    for cluster in data["clusters"]:
        label = str(cluster["name"])
        names = [str(item) for item in cluster.get("entities", []) if str(item) in all_by_name]
        for name in names:
            memberships[name].append(label)
        cluster_rows.append({"name": label, "posts": len(cluster.get("post_ids", [])), "raw_names": names})
    shared_names = {name for name, cluster_names in memberships.items() if len(cluster_names) >= 2}
    clustered_names = set(memberships)
    other_names = sorted(set(all_by_name) - clustered_names, key=lambda name: (-int(all_by_name[name].get("pointer_count", 0)), name.casefold()))
    if other_names:
        cluster_rows.append({"name": "Other entities", "posts": 0, "raw_names": other_names, "other": True})
    posts_for = lambda name: category_pointer_count(all_by_name[name], topic, category_record_ids)
    group_names: dict[str, list[str]] = {}
    collapsed_mentions: dict[str, list[str]] = {}
    group_sizes: dict[str, tuple[int, int]] = {}
    for row in cluster_rows:
        label = row["name"]
        names = row["raw_names"] if row.get("other") else [name for name in row["raw_names"] if name not in shared_names]
        names = sorted(names, key=lambda name: (-posts_for(name), name.casefold()))
        singletons = [name for name in names if posts_for(name) <= 1]
        columns = min(4 if not row.get("other") else 5, max(1, math.ceil(math.sqrt(max(1, len(names))))))
        raw_width = max(720, 48 + columns * 252)
        raw_height = 150 + max(1, math.ceil(len(names) / columns)) * 104
        display_names = [name for name in names if name not in singletons] if raw_width > 900 or raw_height > 700 else names
        collapsed_mentions[label] = singletons if display_names != names else []
        group_names[label] = display_names
        display_count = len(display_names) + (1 if collapsed_mentions[label] else 0)
        columns = min(4 if not row.get("other") else 5, max(1, math.ceil(math.sqrt(max(1, display_count)))))
        group_sizes[label] = (max(720, 48 + columns * 252), min(780, 150 + max(1, math.ceil(display_count / columns)) * 104))
    ring_names = [row["name"] for row in cluster_rows if not row.get("other")]
    ring_sets = {row["name"]: set(row["raw_names"]) for row in cluster_rows if not row.get("other")}
    ordered_ring = _greedy_ring_order(ring_names, ring_sets)
    core_width = 820
    core_height = max(430, min(880, 170 + max(1, len(shared_names)) * 112))
    core_center = (1600.0, 1200.0)
    group_positions: dict[str, tuple[int, int]] = {}
    group_sizes["Shared across clusters"] = (core_width, core_height)
    for index, label in enumerate(ordered_ring):
        similarity = _jaccard(ring_sets[label], set().union(*(ring_sets[other] for other in ring_names if other != label)))
        radius = 1200.0 + min(100.0, max(0.0, 1.0 - similarity) * 100.0)
        angle = -math.pi / 2 + index * (2 * math.pi / max(1, len(ordered_ring)))
        width, height = group_sizes[label]
        group_positions[label] = (round(core_center[0] + radius * math.cos(angle) - width / 2), round(core_center[1] + radius * 0.62 * math.sin(angle) - height / 2))
    if other_names:
        width, height = group_sizes["Other entities"]
        group_positions["Other entities"] = (round(core_center[0] - width / 2), 2200 - height)
    ring_position_map = {label: (float(x), float(y)) for label, (x, y) in group_positions.items() if label != "Other entities"}
    ring_position_map = _resolve_rect_overlaps(ring_position_map, {label: group_sizes[label] for label in ring_position_map}, 3200, 1840, rounds=120)
    for label, (x, y) in ring_position_map.items():
        group_positions[label] = (x, max(340, y))
    core_rect = (round(core_center[0] - core_width / 2), round(core_center[1] - core_height / 2), core_width, core_height)
    for label in ordered_ring:
        x, y = group_positions[label]
        width, height = group_sizes[label]
        for _ in range(4):
            overlap_x = min(x + width, core_rect[0] + core_rect[2]) - max(x, core_rect[0])
            overlap_y = min(y + height, core_rect[1] + core_rect[3]) - max(y, core_rect[1])
            if overlap_x <= 0 or overlap_y <= 0:
                break
            if x + width / 2 < core_center[0]:
                x -= overlap_x + 24
            else:
                x += overlap_x + 24
            x = min(3200 - width, max(10, x))
        group_positions[label] = (round(x), round(y))
    if other_names:
        other_x, other_y = group_positions["Other entities"]
        other_width, other_height = group_sizes["Other entities"]
        other_rect = (other_x, other_y, other_width, other_height)
        for label in ordered_ring:
            x, y = group_positions[label]
            width, height = group_sizes[label]
            overlap_x = min(x + width, other_rect[0] + other_rect[2]) - max(x, other_rect[0])
            overlap_y = min(y + height, other_rect[1] + other_rect[3]) - max(y, other_rect[1])
            if overlap_x > 0 and overlap_y > 0:
                group_positions[label] = (x, max(340, y - overlap_y - 24))
    group_ids: dict[str, str] = {}
    group_order = ["Shared across clusters", *ordered_ring] + (["Other entities"] if other_names else [])
    for label in group_order:
        if label == "Shared across clusters":
            x, y = round(core_center[0] - core_width / 2), round(core_center[1] - core_height / 2)
            group_positions[label] = (x, y)
        else:
            x, y = group_positions[label]
        width, height = group_sizes[label]
        group_ids[label] = add({"type": "group", "label": label, "x": x, "y": y, "width": width, "height": height, "color": category_color})
    entity_topics = {str(entity["canonical"]): [candidate for candidate in TOPIC_LABELS if str(entity["canonical"]) in {str(item["canonical"]) for item in topic_data[candidate]["entities"]}] for entity in entities}
    for row in cluster_rows:
        label = row["name"]
        x, y = group_positions[label]
        width, _height = group_sizes[label]
        names = group_names[label]
        if row.get("other"):
            summary_text = f"## {label}\n{len(row['raw_names'])} entities"
        else:
            summary_line = card_lines["clusters"].get(topic, {}).get(label, {}).get("line", "")
            summary_text = f"## {label}\n{summary_line}\n{row['posts']} posts · {len(row['raw_names'])} entities"
        add({"type": "text", "text": summary_text, "x": x + 24, "y": y + 24, "width": max(420, width - 48), "height": 110, "color": category_color})
        display_entries: list[tuple[str, str]] = [(name, "entity") for name in names]
        if collapsed_mentions.get(label):
            links = [vault_link(f"Entities/{filenames[name]}", name) for name in collapsed_mentions[label]]
            display_entries.append(("Also mentioned\n" + ", ".join(links), "collapsed"))
        columns = min(4 if not row.get("other") else 5, max(1, math.ceil(math.sqrt(max(1, len(display_entries))))))
        max_posts = max([posts_for(name) for name in names] or [1])
        for index, (entry, entry_type) in enumerate(display_entries):
            row_index, column = divmod(index, columns)
            card_x = x + 24 + column * 252
            card_y = y + 150 + row_index * 104
            if entry_type == "collapsed":
                add({"type": "text", "text": "## " + entry, "x": card_x, "y": card_y, "width": 232, "height": 92, "color": category_color})
                continue
            entity = all_by_name[entry]
            posts = posts_for(entry)
            scale = math.sqrt(posts / max_posts) if max_posts else 1
            card_width = round(216 + 16 * scale)
            card_height = round(78 + 12 * scale)
            lines = [f"## {entry}", f"{posts} post{'s' if posts != 1 else ''}"]
            other_topics = [candidate for candidate in entity_topics.get(entry, []) if candidate != topic]
            if other_topics:
                lines.append("↗ also in: " + ", ".join(vault_link("Canvases/" + canvas_filename(candidate), TOPIC_LABELS[candidate]) for candidate in other_topics))
            add({"type": "text", "text": "\n".join(lines), "x": card_x, "y": card_y, "width": card_width, "height": card_height, "color": category_color})
    core_x, core_y = group_positions["Shared across clusters"]
    hub_positions: dict[str, tuple[float, float]] = {}
    for canonical in sorted(shared_names, key=lambda name: (-len(memberships[name]), -posts_for(name), name.casefold())):
        angles = []
        for cluster_name in memberships[canonical]:
            gx, gy = group_positions[cluster_name]
            angles.append(math.atan2(gy + group_sizes[cluster_name][1] / 2 - core_center[1], gx + group_sizes[cluster_name][0] / 2 - core_center[0]))
        vx, vy = sum(math.cos(angle) for angle in angles), sum(math.sin(angle) for angle in angles)
        mean_angle = math.atan2(vy, vx) if vx or vy else 0.0
        hub_positions[canonical] = (math.cos(mean_angle) * 250 + core_width / 2 - 112, math.sin(mean_angle) * 250 + core_height / 2 - 44)
    hub_positions = _resolve_rect_overlaps(hub_positions, {name: (224, 88) for name in hub_positions}, core_width - 40, core_height - 170, rounds=80)
    for canonical, (hx, hy) in hub_positions.items():
        entity = all_by_name[canonical]
        posts = posts_for(canonical)
        lines = [f"## {canonical}", f"{posts} post{'s' if posts != 1 else ''}"]
        other_topics = [candidate for candidate in entity_topics.get(canonical, []) if candidate != topic]
        if other_topics:
            lines.append("↗ also in: " + ", ".join(vault_link("Canvases/" + canvas_filename(candidate), TOPIC_LABELS[candidate]) for candidate in other_topics))
        entity_id = add({"type": "text", "text": "\n".join(lines), "x": round(core_x + 20 + hx), "y": round(core_y + 150 + hy), "width": 224, "height": 88, "color": category_color})
        for cluster_name in memberships[canonical]:
            label = cluster_name if len(cluster_name.split()) <= 4 else None
            edge(entity_id, group_ids[cluster_name], label)
    relation_lookup = {frozenset({item["a"], item["b"]}): item for item in card_lines.get("relations", []) if item.get("line_kind") == "hand-written"}
    for left_index, left in enumerate(cluster_rows):
        if left.get("other"):
            continue
        for right in cluster_rows[left_index + 1 :]:
            if right.get("other"):
                continue
            relation = relation_lookup.get(frozenset({f"{topic}|{left['name']}", f"{topic}|{right['name']}"}))
            if relation:
                edge(group_ids[left["name"]], group_ids[right["name"]], relation["line"])
    add({"type": "text", "text": f"## Shared across clusters\n{len(shared_names)} entities point to multiple clusters", "x": core_x + 24, "y": core_y + 24, "width": core_width - 48, "height": 110, "color": category_color})
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
    card_lines = build_card_lines(topic_data)
    write_json(CARD_LINES_JSON, card_lines)
    canvas = overview_canvas(topic_data, entities, card_lines)
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
        detail = detail_canvas(topic, topic_data[topic], entities, filenames, {}, card_lines, topic_data)
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
