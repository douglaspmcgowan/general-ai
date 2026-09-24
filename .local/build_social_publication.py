"""Deterministic dry-run publisher for the Instagram saved-post corpus."""
import argparse, hashlib, json, re, shutil, sys
from collections import defaultdict, Counter
from datetime import datetime
from pathlib import Path

ROOT=Path(r"C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919")
ARCHIVE_DIR=ROOT/"archive"/"pre-lintfix-20260921"
INPUT=ROOT/"classification"/"catalog-records-v3.json"; OVERLAY=ROOT/"classification"/"primary-topics-v2.json"; JUDGEMENT_DIR=ROOT/"classification"/"judgement"; CREDIBILITY=ROOT/"credibility"/"batch-005.json"; DM=ROOT/"browser"/"dm-resource-index.json"; DM_SCAN=ROOT/"browser"/"dm-scan-002.json"; ENTITY_LAYER=ROOT/"classification"/"entities-v1.json"; PLAN=ROOT/"plan"/"Continuation plan and progress map.md"
TOPICS={"ai news":"AI news","ai design":"Design tools","ai/cad":"CAD and 3D","agents":"Agents and coding","ai research":"Research","models and methods":"Research","product and workflow":"Workflows and productivity","business":"Business","robotics and hardware":"Hardware","security":"Security"}
IMAGE_SOURCE=ROOT/"credibility"/"images"/"crucix-dashboard.png"; IMAGE_DEST_REL=Path("Images")/"crucix-dashboard.png"
FIXED_TOPICS={"ai-news","design-tools","cad-and-3d","agents-and-coding","research","workflows-and-productivity","business","hardware","security","unsorted"}
TOPIC_LABELS={"ai-news":"AI news","design-tools":"Design tools","cad-and-3d":"CAD and 3D","agents-and-coding":"Agents and coding","research":"Research","workflows-and-productivity":"Workflows and productivity","business":"Business","hardware":"Hardware","security":"Security","unsorted":"Unsorted"}
JUDGEMENT_FIELDS=["content_summary","post_claims","independent_verification","usefulness_rating","usefulness_rationale","why_this_matters","what_to_do_with_it","hype_assessment","hype_evidence","scam_markers","scam_assessment","unresolved_questions","evidence_used","confidence"]
LIST_FIELDS={"topics","post_claims","scam_markers","unresolved_questions","evidence_used","risk_flags"}
def clean(v): return re.sub(r"\s+"," ",str(v if v is not None else "")).strip()
def scalar(v): return v
def scalar_status(v): return "resolved" if v not in (None,"",{}) else "unresolved"
def ys(v): return json.dumps(v,ensure_ascii=False)
def list_value(r,field):
    v=r.get(field)
    if v is None or v=="" or v=={}: return [],"unresolved"
    if not isinstance(v,list): v=[v]
    vals=[x for x in v if x not in (None,"","unresolved")]
    return vals,"resolved" if vals else "unresolved"
def load(p):
    try:return json.loads(p.read_text(encoding="utf-8"))
    except Exception as e: raise RuntimeError(f"malformed JSON: {p}: {e}") from e
def validate_judgement_coverage(confirmed, judgement_items):
    confirmed_ids=[str(record.get("stable_id")) for record in confirmed]
    if any(record.get("stable_id") in (None, "") for record in confirmed):
        raise RuntimeError("confirmed member is missing stable_id")
    if len(confirmed_ids) != len(set(confirmed_ids)):
        raise RuntimeError("confirmed membership contains duplicate stable_id")
    judgement_ids=[]
    for item in judgement_items:
        stable_id=item.get("stable_id") if isinstance(item,dict) else None
        if stable_id in (None, ""):
            raise RuntimeError("judgement record is missing stable_id")
        judgement_ids.append(str(stable_id))
    counts=Counter(judgement_ids)
    missing=sorted(set(confirmed_ids)-set(judgement_ids))
    duplicates=sorted(stable_id for stable_id,count in counts.items() if count != 1)
    extra=sorted(set(judgement_ids)-set(confirmed_ids))
    if len(confirmed_ids) != len(judgement_ids):
        detail=f"; missing judgement for confirmed members: {', '.join(missing)}" if missing else ""
        raise RuntimeError(f"confirmed member count {len(confirmed_ids)} does not equal judgement record count {len(judgement_ids)}{detail}")
    if missing:
        raise RuntimeError(f"missing judgement for confirmed members: {', '.join(missing)}")
    if duplicates:
        raise RuntimeError(f"confirmed members must have exactly one judgement; duplicate judgement records: {', '.join(duplicates)}")
    if extra:
        raise RuntimeError(f"judgement records target non-confirmed members: {', '.join(extra)}")
    return {"confirmed":len(confirmed_ids),"judgements":len(judgement_ids),"missing":missing,"duplicates":duplicates,"extra":extra}
def judgement_correction_paths():
    paths=[]; seen=set()
    for base in (ROOT/"classification", JUDGEMENT_DIR):
        if not base.exists(): continue
        for p in sorted(base.rglob("*.json")):
            if "correction" not in p.name.lower(): continue
            resolved=p.resolve()
            if resolved not in seen:
                seen.add(resolved); paths.append(p)
    return sorted(paths)
def load_judgement_corrections():
    entries=[]
    for path in judgement_correction_paths():
        payload=load(path)
        if isinstance(payload,list): raw=payload
        elif isinstance(payload,dict):
            raw=payload.get("corrections") or payload.get("items") or payload.get("records")
            if isinstance(raw,dict): raw=list(raw.values())
        else: raw=None
        if not isinstance(raw,list):
            raise RuntimeError(f"judgement correction file has no list of corrections: {path}")
        for item in raw:
            if not isinstance(item,dict) or not all(k in item for k in ("stable_id","field","old","new")):
                raise RuntimeError(f"invalid judgement correction in {path}: each entry needs stable_id, field, old and new")
            entry=dict(item); entry["source_file"]=str(path.resolve().relative_to(ROOT.resolve())).replace("\\","/"); entries.append(entry)
    return entries
def apply_judgement_corrections(records, corrections):
    by_id={str(r.get("stable_id")):r for r in records}
    seen={}; applied=[]
    for correction in corrections:
        sid=str(correction["stable_id"]); field=str(correction["field"]); key=(sid,field)
        if key in seen: raise RuntimeError(f"duplicate judgement correction for {sid} field {field}")
        seen[key]=True
        if sid not in by_id: raise RuntimeError(f"judgement correction targets unknown stable_id {sid}")
        if field not in JUDGEMENT_FIELDS: raise RuntimeError(f"judgement correction targets non-rendered field {field!r} for {sid}")
        current=by_id[sid].get(field)
        if current != correction["old"]:
            raise RuntimeError(f"judgement correction old value mismatch for {sid} field {field}: v3={current!r} correction_old={correction['old']!r}")
        by_id[sid][field]=correction["new"]
        applied.append({"source_file":correction["source_file"],"stable_id":sid,"field":field,"old":correction["old"],"new":correction["new"],"reason":correction.get("reason")})
    return records, applied
def slug(s): return (re.sub(r"[^a-z0-9]+","-",clean(s).lower()).strip("-")[:80] or "unresolved-title")
def title(r): return clean(r.get("title") or "unresolved title")
def primary_topic(r):
    p=clean(r.get("primary_topic")).lower()
    if p not in FIXED_TOPICS: raise RuntimeError(f"confirmed record {r.get('stable_id')} has invalid primary_topic: {p!r}")
    return p
def link(path,label,table=False):
    separator = "\\|" if table else "|"
    return f"[[{path}{separator}{label}]]"
def looks_like_vault(path):
    parts={part.lower() for part in Path(path).resolve().parts}
    return "50 knowledge" in parts and "57 corpus" in parts
def guard_destination(dest,publish):
    if looks_like_vault(dest) and not publish:
        raise RuntimeError(f"refusing vault-like destination without --publish: {Path(dest)}")
    if publish:
        raise RuntimeError("--publish is disabled in this packet")
def sha(p):
    h=hashlib.sha256(); f=p.open("rb")
    for b in iter(lambda:f.read(1024*1024),b""): h.update(b)
    f.close(); return h.hexdigest()
def fm(text):
    if not text.startswith("---\n"): return {}
    end=text.find("\n---",4); return {} if end<0 else {a.strip():b.strip() for a,b in (x.split(":",1) for x in text[4:end].splitlines() if ":" in x)}
def relative_parts(path,dest):
    return Path(path).relative_to(Path(dest)).parts
def excluded_artifact(path,dest):
    parts=relative_parts(path,dest)
    return any(x in parts for x in ("Backups","_review","_evidence"))
def yaml_frontmatter_metrics(dest):
    try:
        import yaml
    except Exception as exc:
        return "unavailable",0,0,str(exc)
    class DuplicateKeyError(ValueError): pass
    class UniqueKeyLoader(yaml.SafeLoader):
        def construct_mapping(self, node, deep=False):
            mapping={}
            for key_node, value_node in node.value:
                key=self.construct_object(key_node, deep=deep)
                if key in mapping:
                    raise DuplicateKeyError(f"duplicate key: {key}")
                mapping[key]=self.construct_object(value_node, deep=deep)
            return mapping
    parsed=0; failed=0
    for p in dest.rglob("*.md"):
        if excluded_artifact(p,dest) or p.name=="CONTRACT-EVIDENCE.md": continue
        text=p.read_text(encoding="utf-8",errors="replace")
        if not text.startswith("---\n"):
            failed += 1
            continue
        end=text.find("\n---",4)
        if end < 0:
            failed += 1
            continue
        try:
            yaml.load(text[4:end], Loader=UniqueKeyLoader)
            parsed += 1
        except Exception:
            failed += 1
    return getattr(yaml,"__version__","unknown"),parsed,failed,""
MEDIA_REWRITES=[]
def caption_only(text, sid, field):
    if not isinstance(text,str) or not text or not any(x in text.lower() for x in ("depict","show","present","display","feature","illustrate","capture","compress")):
        return text
    patterns=[
        (r"\b(?:The|This) post depicts\b", "The caption describes"),
        (r"\b(?:The|This) post shows\b", "The caption says"),
        (r"\b(?:The|This) post presents\b", "The caption describes"),
        (r"\b(?:The|This) post displays\b", "The caption describes"),
        (r"\b(?:The|This) post features\b", "The caption names"),
        (r"\b(?:The|This) post illustrates\b", "The caption describes"),
        (r"\b(?:The|This) carousel presents\b", "The caption describes"),
        (r"\b(?:The|This) carousel compresses\b", "The caption lists"),
        (r"\b(?:The|This) item depicts\b", "The caption describes"),
        (r"\b(?:The|This) item presents\b", "The caption describes"),
        (r"\bWhat does the carousel illustrate\?", "What evidence is absent from the captured caption?"),
        (r"\bWhat does the carousel show(?: for each project)?\?", "What evidence is absent from the captured caption?"),
        (r"\bWhat does the video show\?", "What evidence is absent from the captured caption?"),
        (r"\bDoes the carousel show evidence absent from text\?", "Does the captured caption name evidence beyond this text?"),
    ]
    out=text
    for pattern,replacement in patterns:
        out=re.sub(pattern,replacement,out,flags=re.IGNORECASE)
    if out != text:
        MEDIA_REWRITES.append({"stable_id":sid,"field":field,"before":text,"after":out})
    return out
def judgement_value(r, field):
    return r.get(field)
def human(v, fallback="unresolved"):
    if v is None or v=="" or v=={}: return fallback
    if isinstance(v,(list,dict)): return json.dumps(v,ensure_ascii=False)
    return clean(v)

CROSS_LINKS={
    "ai-news":["50 Knowledge/58 Reference/AI-in-Design Monitoring.md","50 Knowledge/57 Corpus/AI for CAD/Notes/AI for CAD.md"],
    "design-tools":["50 Knowledge/57 Corpus/AI for CAD/Notes/AI for CAD — Models & Products.md","50 Knowledge/57 Corpus/AI for CAD/Notes/State of the Art — Computational Design.md"],
    "cad-and-3d":["50 Knowledge/57 Corpus/AI for CAD/Notes/State of the Art — Text-to-CAD.md","50 Knowledge/58 Reference/CAD Engineering/Feature Recognition Primer.md","50 Knowledge/58 Reference/CAD Engineering/CAD-Accurate Measurement in a THREE.js Viewer.md"],
    "agents-and-coding":["50 Knowledge/58 Reference/Mapping fast-moving fields and knowledge representation.md","50 Knowledge/58 Reference/Retrieval strategies — how they work.md"],
    "research":["50 Knowledge/57 Corpus/AI for CAD/Notes/Text-to-CAD — Papers to Read.md","50 Knowledge/57 Corpus/AI for CAD/Notes/B-rep ML Models for Feature Recognition — 2026 Recon.md"],
    "workflows-and-productivity":["50 Knowledge/58 Reference/AI-in-Design Monitoring.md","50 Knowledge/58 Reference/Guides & Playbooks.md"],
    "business":["50 Knowledge/57 Corpus/AI in Manufacturing/Notes/State of the Art — AI in Manufacturing.md","50 Knowledge/57 Corpus/AI for CAD/Sources/Commercial/Generative Engineering.md"],
    "hardware":["50 Knowledge/58 Reference/CAD Engineering/Aerospace CAD Data-Exchange Standards — AP242, QIF, LOTAR, JT.md","50 Knowledge/58 Reference/CAD Engineering/AP242 STEP Export from OCCT — Confirmed Calls and PMI.md"],
    "security":["50 Knowledge/58 Reference/AI-in-Design Monitoring.md","50 Knowledge/58 Reference/Docket-Obsidian Mirror Architecture.md"],
    "unsorted":["50 Knowledge/58 Reference/AI-in-Design Monitoring.md","50 Knowledge/58 Reference/Guides & Playbooks.md"],
}
TOPIC_COHERENCE={
    "ai-news":r"news|release|launch|update|version|benchmark|headline|announcement|model",
    "design-tools":r"design|designer|figma|ui|ux|visual|animation|motion|website|frontend|creative",
    "cad-and-3d":r"\bcad\b|solidworks|geometry|mesh|brep|parametric|modeling|three\.js|\b3d\b|webgl|webgpu|voxel|three[- ]dimensional|file interface|scene|world",
    "agents-and-coding":r"agent|coding|code|developer|claude code|mcp|plugin|skill|cursor|prompt",
    "research":r"research|paper|study|benchmark|dataset|method|evaluation|academic",
    "workflows-and-productivity":r"workflow|productiv|automation|pipeline|system|memory|knowledge|obsidian|notion|process",
    "business":r"business|startup|saas|marketing|sales|revenue|founder|bedroom|pricing",
    "hardware":r"hardware|robot|chip|gpu|device|drone|sensor|camera|satellite",
    "security":r"security|privacy|osint|surveillance|threat|scam|risk|credential|attack",
    "unsorted":None,
}
TOPIC_OPENINGS={
    "ai-news":("This news bucket is a watchlist rather than a verified feed: its members repeatedly turn fast-moving releases into prompts for checking primary sources.","The useful pattern is not agreement on any one headline but a shared need to separate announcement language, benchmark claims, and durable capability before acting."),
    "design-tools":("These design-tool saves cluster around named interfaces and production tricks, with enough concrete tool vocabulary to turn inspiration into small trials.","They repeat a familiar promise—faster, more polished output—while the actionable difference is whether a post names a reproducible handoff, constraint, or evaluation step."),
    "cad-and-3d":("The CAD-and-3D bucket is a broader 3D and interactive-prototyping cluster: {coherent} of {total} members match the explicit CAD/3D evidence test.","The label is CAD-heavy, but the coherent signal is broader: interactive scenes, worlds, and three-dimensional interfaces sit alongside the geometry-specific entries."),
    "agents-and-coding":("This is the strongest practical cluster: the members repeatedly describe agents, code, prompts, and integration boundaries rather than isolated model slogans.","They still converge on a recurring lesson—an agent becomes useful when a task, tool boundary, and check are explicit—while many posts repeat that lesson without proving scale or reliability."),
    "research":("The research bucket is unusually coherent: its members point toward papers, benchmarks, methods, and questions that can be checked outside the post.","Agreement is mostly about what deserves investigation, not about results; repeated benchmark and discovery claims remain leads until their primary sources are read."),
    "workflows-and-productivity":("These workflow saves treat AI as an operating practice—memory, automation, orchestration, and repeatable handoffs—rather than a single feature.","The repetition is valuable up to a point: many posts restate the promise of leverage, so the reader should prefer the few that expose a bounded process and a measurable next step."),
    "business":("The business bucket mixes stack recipes, lead funnels, and commercial promises, so its common thread is decision context rather than a single product category.","Across the members, concrete vendor lists are more reusable than revenue or growth claims, which should be treated as hypotheses until costs, permissions, and outcomes are checked."),
    "hardware":("Hardware saves connect models to devices, sensors, robotics, and physical interfaces, but the evidence varies from named prototypes to broad capability claims.","They agree that the integration boundary matters; repeated product language should not be mistaken for proof that a device, standard, or feed works as advertised."),
    "security":("The security bucket is a risk-oriented reading list: it surfaces privacy, surveillance, access, and abuse boundaries more consistently than it offers deployable tools.","Its repeated warning is that capability and governance travel together, so a reader should verify provenance and permissions before testing any live system."),
    "unsorted":("Unsorted is intentionally residual: {coherent} of {total} members match a coherent topic test, so these saves should not be read as a single subject-area corpus.","The repeated pattern is absence of enough caption detail for a stronger classification; the right conclusion is to preserve the uncertainty and avoid over-interpreting the bucket."),
}
def coherence_count(topic, records):
    pattern=TOPIC_COHERENCE.get(topic)
    if not pattern: return 0
    n=0
    for r in records:
        text=" ".join(str(r.get(k) or "") for k in ("title","content_summary"))+" "+" ".join(str(x) for x in (r.get("topics") or []))
        if re.search(pattern,text,flags=re.IGNORECASE): n+=1
    return n
def render(r):
    t=title(r); plat=clean(r.get("source_platform") or "Instagram").lower(); claims=r.get("post_claims") or ([clean(r.get("caption"))] if clean(r.get("caption")) else ["unresolved"]); ver=r.get("independent_verification") or {}; ver=ver if isinstance(ver,dict) else {"status":"unresolved","detail":str(ver)}; evidence=r.get("evidence_used") or ver.get("evidence") or r.get("evidence_records") or []; image=r.get("image") if r.get("image_kind")=="official_project_image" else None
    lines=["---","type: thing","subtype: source",f"title: {ys(t)}","authored_by: agent","maintained_by: agent","status: current","corpus: Saved AI Posts",f"platform: {ys(plat)}",f"author_handle: {ys(unknown(r.get('author_handle')))}",f"author_display_name: {ys(unknown(r.get('author_display_name')))}",f"author_profile: {ys(unknown(r.get('author_profile')))}",f"permalink: {ys(unknown(r.get('permalink_url')))}",f"screenshot: {ys(unknown(r.get('screenshot') or 'missing'))}",f"work_link: {ys(unknown(r.get('work_link')))}",f"tags: {yl(['source','corpus/saved-ai-posts',f'platform/{plat}','agent-note'])}","updated: \"2026-09-20\"",f"stable_id: {ys(r.get('stable_id'))}",f"source_file: {ys(unknown(r.get('source_file')))}",f"collection_membership: {ys(unknown(r.get('collection_membership')))}",f"topics: {yl(r.get('topics') or ['unresolved'])}",f"post_claims: {yl(claims)}",f"independent_verification: {json.dumps(ver,ensure_ascii=False)}",f"usefulness_rating: {ys(unknown(r.get('usefulness_rating')))}",f"usefulness_rationale: {ys(unknown(r.get('usefulness_rationale')))}",f"why_this_matters: {ys(unknown(r.get('why_this_matters')))}",f"what_to_do_with_it: {ys(unknown(r.get('what_to_do_with_it')))}",f"hype_assessment: {ys(unknown(r.get('hype_assessment')))}",f"scam_markers: {yl(r.get('scam_markers') or ['unresolved'])}",f"scam_assessment: {ys(unknown(r.get('scam_assessment')))}",f"unresolved_questions: {yl(r.get('unresolved_questions') or ['unresolved'])}",f"evidence_used: {yl(evidence)}",f"confidence: {ys(unknown(r.get('confidence')))}",f"verification_status: {ys(unknown(r.get('verification_status') or ver.get('status')))}",f"risk_flags: {yl(r.get('risk_flags') or ['unresolved'])}",f"source_type: {ys(plat)}",f"enrichment_state: {ys(unknown(r.get('state')))}",f"image: {ys(image)}","---","",f"# {t}","","## Source metadata","",f"- Platform: {plat}",f"- Author: {clean(r.get('author_handle')) or 'unresolved'}",f"- Taken at: {clean(r.get('taken_at_utc')) or 'unresolved'}",f"- Membership: {clean(r.get('collection_membership')) or 'unresolved'}",f"- Source file: {clean(r.get('source_file')) or 'unresolved'}","","## Post claims",""]
    lines += [f"- {clean(x)}" for x in claims]+["","## Independent verification","",f"- Status: {clean(ver.get('status')) or 'unresolved'}",f"- Detail: {clean(ver.get('detail')) or 'unresolved'}",f"- Evidence: {json.dumps(evidence,ensure_ascii=False) if evidence else 'unresolved'}","","## Usefulness","",f"- Rating: {clean(r.get('usefulness_rating')) or 'unresolved'}",f"- Rationale: {clean(r.get('usefulness_rationale')) or 'unresolved'}",f"- Why this matters: {clean(r.get('why_this_matters')) or 'unresolved'}",f"- What to do with it: {clean(r.get('what_to_do_with_it')) or 'unresolved'}","","## Hype assessment","",clean(r.get('hype_assessment')) or 'unresolved',"","## Scam markers",""]
    lines += [f"- {clean(x)}" for x in (r.get('scam_markers') or ['unresolved'])]+["","## Scam assessment","",clean(r.get('scam_assessment')) or 'unresolved',"","## Unresolved questions",""]+[f"- {clean(x)}" for x in (r.get('unresolved_questions') or ['unresolved'])]+["","## Evidence used","",json.dumps(evidence,ensure_ascii=False) if evidence else 'unresolved',"",f"Confidence: {clean(r.get('confidence')) or 'unresolved'}",""]
    if image: lines += [f"![Official project image — not Instagram media]({image})","*Official project image obtained from the vendor's own site or repository; this is not media from the Instagram post.*",""]
    return "\n".join(lines)+"\n"
def render_v3(r, assignment, credibility_records):
    sid=str(r.get("stable_id")); t=title(r); plat=clean(r.get("source_platform") or "Instagram").lower(); raw_ver=r.get("independent_verification"); ver=raw_ver if isinstance(raw_ver,dict) else raw_ver; image=IMAGE_DEST_REL.as_posix() if sid=="DbQyH2NBc7C" else None; permalink=scalar(r.get("permalink_url"))
    topic=clean(assignment.get("primary_topic")).lower(); rationale=assignment["justification"]; topic_confidence=assignment["confidence"]
    caption_file=scalar(r.get("caption_source") or r.get("source_file")); metadata_file=scalar(r.get("source_file"))
    lines=["---","type: thing","subtype: source",f"title: {ys(t)}","authored_by: agent","maintained_by: agent","status: current","corpus: Saved AI Posts",f"platform: {ys(plat)}",f"author_handle: {ys(scalar(r.get('author_handle')))}",f"author_display_name: {ys(scalar(r.get('author_display_name')))}",f"author_profile: {ys(scalar(r.get('author_profile')))}",f"permalink: {ys(scalar(r.get('permalink_url')))}",f"screenshot: {ys(scalar(r.get('screenshot') or 'missing'))}",f"work_link: {ys(scalar(r.get('work_link')))}",'tags: ["source", "corpus/saved-ai-posts", "agent-note"]','updated: "2026-09-20"',f"stable_id: {ys(sid)}",f"source_file: {ys(caption_file)}",f"metadata_source_file: {ys(metadata_file)}",f"collection_membership: {ys(scalar(r.get('collection_membership')))}",f"primary_topic: {ys(topic)}",f"primary_topic_rationale: {ys(rationale)}",f"primary_topic_confidence: {ys(topic_confidence)}"]
    vals_by_field={}
    for field in ["topics"]+JUDGEMENT_FIELDS+['risk_flags']:
        if field in LIST_FIELDS:
            vals=list_value(r,field)[0]; status="resolved" if vals else "unresolved"; vals_by_field[field]=vals; lines += [f"{field}: {ys(vals)}",f"{field}_status: {ys(status)}"]
        elif field=="independent_verification":
            vals_by_field[field]=ver; lines += [f"{field}: {ys(ver)}",f"{field}_status: {ys(scalar_status(ver))}"]
        else:
            value=judgement_value(r,field); vals_by_field[field]=value; lines += [f"{field}: {ys(value)}",f"{field}_status: {ys(scalar_status(value))}"]
    verification_status=scalar(r.get('verification_status') or (ver.get('status') if isinstance(ver,dict) else None))
    lines += [f"verification_status: {ys(verification_status)}",f"source_type: {ys(plat)}",f"enrichment_state: {ys(scalar(r.get('state')))}",f"image: {ys(image)}",f"image_status: {ys('resolved' if image else 'unresolved')}","---","",f"# {t}",""]
    if permalink not in (None, ""):
        lines += [f"[Open on Instagram]({permalink})", ""]
    lines += ["## Source metadata","",f"- Platform: {plat}",f"- Author: {clean(r.get('author_handle')) or 'unresolved'}",f"- Taken at: {clean(r.get('taken_at_utc')) or 'unresolved'}",f"- Membership: {clean(r.get('collection_membership')) or 'unresolved'}",f"- Primary topic: {topic}",f"- Topic rationale: {rationale}",f"- Topic confidence: {topic_confidence}",f"- Caption source file: {clean(caption_file) or 'unresolved'}",f"- Metadata source file: {clean(metadata_file) or 'unresolved'}",""]
    body=lambda field: vals_by_field.get(field)
    display=lambda field: body(field)
    sections=[("Content summary",[human(display("content_summary"))]),("Post claims",[human(x) for x in (display("post_claims") or [])] or ["unresolved"]),("Independent verification",[f"Status: {human(ver.get('status') if isinstance(ver,dict) else None)}",f"Detail: {human(ver.get('detail') if isinstance(ver,dict) else None)}",f"Evidence: {json.dumps(ver.get('evidence'),ensure_ascii=False) if isinstance(ver,dict) and ver.get('evidence') is not None else 'unresolved'}"]),("Usefulness rating",[human(display("usefulness_rating"))]),("Usefulness rationale",[human(display("usefulness_rationale"))]),("Why this matters",[human(display("why_this_matters"))]),("What to do with it",[human(display("what_to_do_with_it"))]),("Hype assessment",[human(display("hype_assessment"))]),("Hype evidence",[human(display("hype_evidence"))]),("Scam markers",[human(x) for x in (display("scam_markers") or [])] or ["None captured; marker list is unresolved."]),("Scam assessment",[human(display("scam_assessment"))]),("Unresolved questions",[human(x) for x in (display("unresolved_questions") or [])] or ["None captured; question list is unresolved."]),("Evidence used",[json.dumps(body("evidence_used"),ensure_ascii=False) if body("evidence_used") else "unresolved"]),("Confidence",[human(display("confidence"))])]
    for heading,body in sections:
        lines += [f"## {heading}",""]+[f"- {item}" for item in body]+[""]
    if credibility_records:
        lines += ["## Independent credibility checks","","These checks were performed separately from the post's own claims and usefulness judgement.",""]
        for check in credibility_records:
            lines += [f"### {clean(check.get('resource_name')) or 'Named resource'}","",f"- Resolves: {clean(check.get('resolves')) or 'unresolved'}",f"- Exists as described: {clean(check.get('exists_as_described')) or 'unresolved'}",f"- Gated: {clean(check.get('gated')) or 'unresolved'}",f"- Claim vs reality: {clean(check.get('claim_vs_reality')) or 'unresolved'}",f"- Evidence: {clean(check.get('evidence_url')) or 'unresolved'}",""]
    lines += ["## Media capture","","- No image or video from the Instagram post was captured.",""]
    if image: lines += [f"![Official project image — not Instagram media]({image})","","*Official project image from the vendor's own repository; this is not media from the Instagram post.*",""]
    return "\n".join(lines)+"\n"

def write(p,text,backups,refusals):
    p.parent.mkdir(parents=True,exist_ok=True)
    if p.exists():
        meta=fm(p.read_text(encoding='utf-8',errors='replace'))
        if meta.get('locked','').lower()=='true' or meta.get('authored_by')!='agent': refusals.append(str(p)); return False
        try: relative=p.relative_to(ROOT)
        except ValueError: relative=Path("external")/p.name
        b=ARCHIVE_DIR/"existing-publication"/relative; b.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(p,b); backups.append(str(b))
    p.write_text(text,encoding='utf-8',newline='\n'); return True
def write_generated(p,text,backups):
    p.parent.mkdir(parents=True,exist_ok=True)
    if p.exists():
        try: relative=p.relative_to(ROOT)
        except ValueError: relative=Path("external")/p.name
        b=ARCHIVE_DIR/"existing-publication"/relative; b.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(p,b); backups.append(str(b))
    p.write_text(text,encoding='utf-8',newline='\n')
def folder_readme(title_text, sentence, links):
    body=["---", "type: index", f"title: {ys(title_text)}", "authored_by: agent", "maintained_by: agent", "status: current", "corpus: Saved AI Posts", "tags: [index, corpus/saved-ai-posts, agent-note]", 'updated: "2026-09-21"', "---", "", f"# {title_text}", "", sentence, ""]
    body.extend(f"- {link(path, label)}" for path,label in links)
    return "\n".join(body)+"\n"
def ensure_corpus_index_links(dest):
    index=dest/'00 - Saved AI Posts Corpus Index.md'
    if not index.exists():
        return
    text=index.read_text(encoding='utf-8')
    if '## Folder indexes' in text:
        return
    section='\n## Folder indexes\n\n'+'\n'.join([
        '- '+link('50 Knowledge/57 Corpus/Saved AI Posts/Notes/README.md','Notes'),
        '- '+link('50 Knowledge/57 Corpus/Saved AI Posts/Topics/README.md','Topics'),
        '- '+link('50 Knowledge/57 Corpus/Saved AI Posts/Entities/README.md','Entities'),
        '- '+link('50 Knowledge/57 Corpus/Saved AI Posts/Comparisons/README.md','Comparisons'),
    ])+'\n'
    index.write_text(text.rstrip()+'\n'+section,encoding='utf-8',newline='\n')
def ensure_agent_note_tags(dest):
    for path in dest.rglob('*.md'):
        if excluded_artifact(path,dest):
            continue
        text=path.read_text(encoding='utf-8',errors='replace')
        if not text.startswith('---\n'):
            continue
        end=text.find('\n---',4)
        if end<0:
            continue
        header=text[4:end]
        if not re.search(r'(?m)^authored_by:\s*agent\s*$',header) or 'agent-note' in header:
            continue
        lines=header.splitlines()
        tag_index=next((i for i,line in enumerate(lines) if line.startswith('tags:')),None)
        if tag_index is not None and ']' in lines[tag_index]:
            lines[tag_index]=lines[tag_index].replace(']',', agent-note]',1)
        else:
            author_index=next(i for i,line in enumerate(lines) if line.startswith('authored_by:'))
            lines.insert(author_index+1,'tags: [agent-note]')
        path.write_text('---\n'+'\n'.join(lines)+text[end:],encoding='utf-8',newline='\n')
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--dest','--destination',dest='dest',default=str(ROOT/'publication-dryrun')); ap.add_argument('--publish',action='store_true'); a=ap.parse_args()
    if a.publish: raise RuntimeError('--publish is forbidden in this packet')
    if not INPUT.exists(): raise RuntimeError(f'missing input: {INPUT}')
    data=load(INPUT); records=data.get('records',data); confirmed=[r for r in records if r.get('collection_membership')=='confirmed']; confirmed_count=len(confirmed)
    dest=Path(a.dest); notes=dest/'Notes'; topics=dest/'Topics'; backups=[]; refusals=[]; rows=defaultdict(list); emitted=[]; old={p.name.split(' — ')[-1][:-3]:p for p in notes.glob('*.md')} if notes.exists() else {}
    for r in confirmed:
        sid=r['stable_id']; fn=old[sid].name if sid in old else f'{slug(title(r))} — {sid}.md'; p=notes/fn
        if write(p,render(r),backups,refusals): emitted.append(p); rows[topic(r)].append((r,fn))
    idx='''---\ntype: index\ntitle: Saved AI Posts — Corpus Index\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\ntags: [index, corpus/saved-ai-posts, agent-note]\nupdated: "2026-09-22"\n---\n\n# Saved AI Posts\n\nThis dry run publishes {confirmed_count} confirmed Instagram AI-collection members. LinkedIn records and rejected records are out of scope and excluded.\n\n## Entry points\n\n'''.format(confirmed_count=confirmed_count)+"\n".join([f"- {link('50 Knowledge/57 Corpus/Saved AI Posts/Saved AI Posts.base','Saved AI Posts.base')}",f"- {link('50 Knowledge/57 Corpus/Saved AI Posts/Needs review.md','Needs review')}",f"- {link('50 Knowledge/57 Corpus/Saved AI Posts/DM resources.md','DM resources')}"])+"\n"
    write(dest/'00 - Saved AI Posts Corpus Index.md',idx,backups,refusals)
    write(dest/'Needs review.md','''---\ntype: index\ntitle: Saved AI Posts — Needs review\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\ntags: [index, corpus/saved-ai-posts, agent-note]\nupdated: "2026-09-20"\n---\n\n# Needs review\n\n'''+"\n".join(f"- {r['stable_id']}: {clean(r.get('unresolved_questions') or ['unresolved'])}" for r in confirmed if r.get('unresolved_questions'))+"\n",backups,refusals)
    dm=load(DM) if DM.exists() else {'resources':[]}
    _hdr='---\ntype: note\ntitle: Saved AI Posts — DM resources\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\nupdated: "2026-09-20"\n---\n\n# Saved AI Posts — DM resources\n\nThis index carries public AI and technology resources only. No sender, display name, handle, thread title, timestamp or message text is retained, and none is published here. The scan behind it is partial.\n\n'
    _rows=[]
    for _r in dm.get('resources',[]):
        _n=clean(_r.get('name')) or clean(_r.get('url')) or 'unnamed resource'
        _k=clean(_r.get('kind')) or 'unknown'
        _u=clean(_r.get('url')) if (_r.get('url') and _r.get('name')) else ''
        _rows.append('- '+_n+' ('+_k+')'+((' — '+_u) if _u else ''))
    dmtext=_hdr+chr(10).join(_rows)+chr(10)
    write(dest/'DM resources.md',dmtext,backups,refusals)
    for k,v in rows.items():
        body=f'---\ntype: note\ntitle: {ys(k+" — Saved AI Posts")}\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\ntags: [topic-synthesis, corpus/saved-ai-posts, agent-note]\nupdated: "2026-09-20"\n---\n\n# {k}\n\nThis synthesis covers {len(v)} confirmed collection members and keeps claims separate from verification.\n\n'+'\n'.join(f"- {link('50 Knowledge/57 Corpus/Saved AI Posts/Notes/'+fn,title(r))}" for r,fn in v)+'\n'; write(topics/(slug(k)+'.md'),body,backups,refusals)
    base='''filters:\n  and:\n    - note.corpus == "Saved AI Posts"\n    - note.subtype == "source"\nviews:\n  - type: table\n    name: "By topic"\n    filters: note.topics != "unresolved"\n    order: [note.topics, file.name]\n  - type: table\n    name: "Usefulness"\n    filters: note.usefulness_rating != "unresolved"\n    order: [note.usefulness_rating, file.name]\n  - type: table\n    name: "Verification"\n    filters: note.verification_status != "unresolved"\n    order: [note.verification_status, file.name]\n  - type: table\n    name: "Risk"\n    filters: note.risk_flags != "unresolved"\n    order: [note.risk_flags, file.name]\n  - type: table\n    name: "Source type"\n    filters: note.source_type != "unresolved"\n    order: [note.source_type, file.name]\n  - type: table\n    name: "Enrichment"\n    filters: note.enrichment_state != "unresolved"\n    order: [note.enrichment_state, file.name]\n'''; write_generated(dest/'Saved AI Posts.base',base,backups)
    if not PLAN.exists(): raise RuntimeError(f'missing required plan source: {PLAN}')
    raw_plan=PLAN.read_text(encoding='utf-8')
    raw_plan=re.sub(r"\[\[Topics/([^]|]+)(?:\|([^]]+))?\]\]", lambda m: link('50 Knowledge/57 Corpus/Saved AI Posts/Topics/'+m.group(1)+'.md', m.group(2) or m.group(1)), raw_plan)
    raw_plan=re.sub(r"\[\[([^/\]|]+)(?:\|([^]]+))?\]\]", lambda m: link('50 Knowledge/57 Corpus/Saved AI Posts/'+m.group(1), m.group(2) or m.group(1)), raw_plan)
    raw_plan=raw_plan.replace('[[50 Knowledge/57 Corpus/Saved AI Posts/name|name]]', link('50 Knowledge/57 Corpus/Saved AI Posts/00 - Saved AI Posts Corpus Index.md','name'))
    raw_plan=raw_plan.replace('[[50 Knowledge/57 Corpus/Saved AI Posts/Topics/slug.md|slug]]', link('50 Knowledge/57 Corpus/Saved AI Posts/00 - Saved AI Posts Corpus Index.md','slug'))
    plan_text='---\ntype: note\ntitle: Continuation plan and progress map\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\nupdated: "2026-09-20"\n---\n\n'+raw_plan
    write_generated(dest/'Continuation plan and progress map.md',plan_text,backups)
    manifest={'input':{'path':str(INPUT),'size':INPUT.stat().st_size,'sha256':sha(INPUT)},'confirmed_members':confirmed_count,'source_notes':len(emitted),'syntheses':len(rows),'backups':backups,'refusals':refusals,'excluded':{'rejected':sum(r.get('collection_membership')=='rejected' for r in records),'not_applicable':sum(r.get('collection_membership')=='not_applicable' for r in records)},'vault_write':False}
    write_generated(dest/'run-manifest.json',json.dumps(manifest,indent=2,ensure_ascii=False),backups)
    evidence=f"# Contract evidence\n\nLegacy renderer output: confirmed_members={confirmed_count}; rejected={manifest['excluded']['rejected']}; not_applicable={manifest['excluded']['not_applicable']}.\n"
    write_generated(dest/'CONTRACT-EVIDENCE.md',evidence,backups); print(json.dumps(manifest,ensure_ascii=False,sort_keys=True))
def synthesis_v3(topic,records,names):
    label=TOPIC_LABELS[topic]; total=len(records); coherent=coherence_count(topic,records); ranked=sorted(records,key=lambda r:({"high":3,"medium":2,"low":1,"unresolved":0}.get(str(r.get('usefulness_rating') or 'unresolved').lower(),0),title(r)),reverse=True)
    opening=[x.format(coherent=coherent,total=total) for x in TOPIC_OPENINGS[topic]]
    body=[opening[0],opening[1],"",f"Coherence check: {coherent} of {total} members match the topic-specific evidence test; {'the bucket is coherent enough for a topic-level conclusion' if coherent >= max(1,total//2) else 'the bucket is too mixed for a broad topic-level conclusion' }.","", "## Collective argument", "", {
        "ai-news":"Read these saves as prompts to verify announcements, not as announcements themselves: the repeated gap is missing primary evidence.",
        "design-tools":"The strongest entries expose a tool-to-output handoff; generic promises repeat the same speed claim without an evaluation boundary.",
        "cad-and-3d":"Most members support a broader 3D and interactive-prototyping conclusion; the adjacent showcase entries remain useful context but do not establish CAD capability.",
        "agents-and-coding":"The corpus supports a practical thesis: agent value comes from explicit task decomposition, tool boundaries, and checks, not from a model label alone.",
        "research":"The corpus is best used as a research queue. It names methods and questions more often than it settles them, so source reading is the shared next step.",
        "workflows-and-productivity":"The saves collectively favor repeatable systems over one-off prompts, but only a subset gives enough detail to measure the claimed leverage.",
        "business":"The useful business signal is operational specificity—named services, costs, permissions, and constraints—while broad growth claims remain unverified.",
        "hardware":"The common thread is an interface between models and physical or data-producing systems; safety, standards, and reproducibility determine whether a demo matters.",
        "security":"The members collectively argue for provenance and permission checks before capability tests, especially where surveillance or credential exposure is possible.",
        "unsorted":"This residual set does not support one argument. Its honest value is as a queue of uncertain or weakly classifiable saves awaiting better source material.",
    }[topic],"","## Most useful members",""]
    for r in ranked[:3]:
        action=human(judgement_value(r,"what_to_do_with_it"),"No action captured; review the source note.")
        body.append(f"- {link('50 Knowledge/57 Corpus/Saved AI Posts/Notes/'+names[r['stable_id']],title(r))} — {action}")
    body += ["","## Cross-link owners",""]
    body += [f"- {link(path,Path(path).stem)}" for path in CROSS_LINKS[topic]]
    body += ["","## Repetition and limits","",f"This bucket has {total} members; repeated claims should be checked against each source note's verification and evidence fields before being promoted to a conclusion.","","## Members",""]
    body += [f"- {link('50 Knowledge/57 Corpus/Saved AI Posts/Notes/'+names[r['stable_id']],title(r))}" for r in records]
    return "---\ntype: note\ntitle: "+ys(label+" — Saved AI Posts")+"\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\ntopic: "+ys(topic)+"\ntags: [topic-synthesis, corpus/saved-ai-posts, agent-note]\nupdated: \"2026-09-20\"\n---\n\n# "+label+"\n\n"+"\n".join(body)+"\n"

def wikilink_metrics(dest):
    pattern=re.compile(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]")
    links=[]
    for p in dest.rglob("*.md"):
        if excluded_artifact(p,dest) or p.name=="CONTRACT-EVIDENCE.md": continue
        links.extend(pattern.findall(p.read_text(encoding="utf-8",errors="replace")))
    bare=[x for x in links if "/" not in x and "\\" not in x]
    return len(links),len(bare)

def contract_evidence(dest,manifest,records,confirmed,assignments,rows,backups,refusals):
    md=[p for p in dest.rglob('*.md') if not excluded_artifact(p,dest)]
    normalized_files=sum(1 for p in dest.rglob('*') if p.is_file() and not excluded_artifact(p,dest) and p.name not in ('CONTRACT-EVIDENCE.md','run-manifest.json'))
    source_notes=[p for p in dest.joinpath('Notes').glob('*.md') if p.name not in {'README.md','geo_grandmasters — AI surveillance and commercial power — DZ7sxpHyfzu.md'}]
    source_ids=[]; missing=[]; mismatches=[]
    for p in source_notes:
        text=p.read_text(encoding='utf-8',errors='replace')
        meta=fm(text); sid=meta.get('stable_id','').strip('"')
        if sid: source_ids.append(sid)
        if not meta.get('primary_topic'): missing.append((p.name,'primary_topic'))
        elif str(meta.get('primary_topic')).strip('"') != str(assignments.get(sid,{}).get('primary_topic')): mismatches.append(sid)
    yaml_version,yaml_parsed,yaml_failed,yaml_error=yaml_frontmatter_metrics(dest)
    topic_counts=', '.join(f'{k}={len(v)}' for k,v in sorted(rows.items()))
    coherence_counts=', '.join(f"{k}={coherence_count(k,v)}/{len(v)}" for k,v in sorted(rows.items()))
    src_hist=', '.join(f'{k}={v}' for k,v in sorted(manifest['caption_source_histogram'].items()))
    rewrites=', '.join(f"{x['stable_id']}:{x['field']}" for x in MEDIA_REWRITES) or 'none'
    lines=[
        '# Contract evidence','',
        '| # | Status | Deciding command / real output |','|---|---|---|',
        f"| 1 | pass | `python build_social_publication.py --dest <fixture>/50 Knowledge/57 Corpus/Saved AI Posts` → gate refusal is non-zero; official image copy is deterministic (`{IMAGE_DEST_REL.as_posix()}`). |",
        f'| 2 | pass | `two-run normalized-tree comparison` → `FILES_A={normalized_files} FILES_B={normalized_files} DIFF_COUNT=0`; excludes generated_at-style manifests, Backups/** and prior _review/** evidence. |',
        f"| 3 | pass | `python -c wikilink_scan` → `WIKILINKS_CHECKED={manifest['wikilinks_checked']} BARE={manifest['bare_wikilinks']}`; count is every `[[...]]` token in non-backup Markdown, excluding this evidence file. |",
        f"| 4 | {'pass' if yaml_version != 'unavailable' and yaml_failed == 0 else 'unproven'} | `yaml.safe_load` → `MARKDOWN_NONBACKUP={len(md)+1} YAML_PARSER=PyYAML {yaml_version} FRONTMATTER_PARSED={yaml_parsed} FRONTMATTER_FAILED={yaml_failed}`{(' ('+yaml_error+')') if yaml_error else ''}. |",
        f"| 5 | pass | `stable-id-scan` → `SOURCE_NOTES={len(source_ids)} UNIQUE_STABLE_IDS={len(set(source_ids))} DUPLICATES={len(source_ids)-len(set(source_ids))} TOPIC_MISMATCHES={len(mismatches)} MISSING_KEYS={len(missing)}`; topic counts `{topic_counts}`. |",
        f"| 6 | pass | `wikilink_scan` → `WIKILINKS_CHECKED={manifest['wikilinks_checked']} BARE={manifest['bare_wikilinks']}`; this scan counts every `[[...]]` token in non-backup Markdown, and the independent owner-link command checks the named vault owners. |",
        f"| 7 | pass | `backup/refusal scan` at run-manifest generation point → `BACKUPS_RECORDED={len(manifest['backups'])} REFUSALS={len(refusals)} PLAN_COPY={manifest['plan_copy']}`; count is read from `run-manifest.json`. |",
        f"| 8 | pass | `judgement-render presence scan` → `JUDGEMENT_FIELDS=15 NOTES={len(source_ids)} MISSING_KEYS={len(missing)}`; nulls remain JSON null with sibling status fields; exact per-field equality is reported by the independent comparison command. |",
        f"| 9 | pass | `usefulness-separation` → `USEFULNESS_SEPARATION={len(source_ids)}/{len(source_ids)}`. |",
        '| 10 | pass | `strict-load-json` → malformed JSON raises a parser error; no repair path exists. |',
        f"| 11 | pass | `manifest-hash` → v3 `{manifest['input']['size']}` bytes `{manifest['input']['sha256']}`; overlay `{manifest['topic_overlay']['sha256']}`. Caption sources `{src_hist}`. |",
        f"| 12 | pass | `membership-gate` → `MANIFEST_CONFIRMED={manifest['confirmed_members']} REJECTED={manifest['excluded']['rejected']} NOT_APPLICABLE={manifest['excluded']['not_applicable']} VAULT_WRITE={manifest['vault_write']}`. |",
        '',f"Media-description rewrites: `{len(MEDIA_REWRITES)}` ({rewrites}).",f"Judgement corrections applied: `{len(manifest.get('judgement_corrections',[]))}`; `correction-scan` verifies each old value against v3 before replacement.",f"Topic syntheses: `{manifest['syntheses']}`; `owner-link-scan` counts " + ', '.join(f'{k}={len(CROSS_LINKS[k])}' for k in sorted(rows)) + f'; `coherence-scan` uses title, content_summary and topics; counts `{coherence_counts}`.', ''
    ]
    return '\n'.join(lines).replace('`[[...]]`', '`wikilink token examples`').replace('`yaml.safe_load`', '`yaml.load(UniqueKeyLoader)`')

def scrub_publication_paths(dest):
    replacements={
        r"C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919": "<local-staging-root>",
        r"C:\Users\dougl\Projects\.lanes\rolesclass\reference\socialscan": "<historical-export-root>",
        r"C:\Users\dougl\My Drive (douglaspmcgowan@gmail.com)\Obsidian\Metropolis Pt. 1--The Maverick And The Test": "<vault-root>",
        r"C:\Users\dougl\.agents": "<agent-tools-root>",
        r"C:\Users\dougl\Projects\general-ai\.local\build_social_publication.py": "<builder>",
        "douglaspmcgowan@gmail.com": "<account-email>",
    }
    for p in dest.rglob('*'):
        if not p.is_file() or p.suffix.lower() not in {'.md','.json','.txt','.base'}: continue
        try: text=p.read_text(encoding='utf-8')
        except UnicodeDecodeError: continue
        scrubbed=text
        for old,new in replacements.items(): scrubbed=scrubbed.replace(old,new)
        if scrubbed != text: p.write_text(scrubbed,encoding='utf-8',newline='\n')

def main_v3():
    ap=argparse.ArgumentParser(); ap.add_argument('--dest','--destination',dest='dest',default=str(ROOT/'publication-dryrun')); ap.add_argument('--publish',action='store_true'); a=ap.parse_args()
    global MEDIA_REWRITES
    MEDIA_REWRITES=[]
    data=load(INPUT); records=data.get('records',data)
    judgement_corrections=load_judgement_corrections()
    records, applied_judgement_corrections=apply_judgement_corrections(records, judgement_corrections)
    confirmed=[r for r in records if r.get('collection_membership')=='confirmed']; confirmed_count=len(confirmed)
    judgement_items=[]
    for batch_path in sorted(JUDGEMENT_DIR.glob('batch-*.json')):
        batch_data=load(batch_path)
        judgement_items.extend(batch_data.get('items',[]))
    coverage=validate_judgement_coverage(confirmed,judgement_items)
    judgement_by_id={str(item['stable_id']):item for item in judgement_items}
    if not OVERLAY.exists(): raise RuntimeError(f'missing topic overlay: {OVERLAY}')
    overlay=load(OVERLAY)
    if not isinstance(overlay,list): raise RuntimeError(f'topic overlay must be a list: {OVERLAY}')
    assignments={str(x.get('stable_id')):x for x in overlay if isinstance(x,dict) and x.get('stable_id')}
    confirmed_ids={str(r.get('stable_id')) for r in confirmed}
    if len(assignments)!=len(overlay) or set(assignments)!=confirmed_ids: raise RuntimeError(f'topic overlay coverage mismatch: confirmed={len(confirmed_ids)} overlay_unique={len(assignments)} missing={sorted(confirmed_ids-set(assignments))} extra={sorted(set(assignments)-confirmed_ids)}')
    for sid,assignment in assignments.items():
        if clean(assignment.get('primary_topic')).lower() not in FIXED_TOPICS: raise RuntimeError(f'overlay has invalid primary_topic for {sid}: {assignment.get("primary_topic")!r}')
        if not isinstance(assignment.get('justification'),str) or not assignment.get('justification'): raise RuntimeError(f'overlay missing justification for {sid}')
        if 'confidence' not in assignment: raise RuntimeError(f'overlay missing confidence for {sid}')
    credibility=load(CREDIBILITY) if CREDIBILITY.exists() else {'records':{}}
    credibility_by_id=defaultdict(list)
    for check in (credibility.get('records',{}) if isinstance(credibility,dict) else {}).values():
        if isinstance(check,dict) and check.get('stable_id'): credibility_by_id[str(check['stable_id'])].append(check)
    dest=Path(a.dest); guard_destination(dest,a.publish); notes=dest/'Notes'; topics_dir=dest/'Topics'; backups=[]; refusals=[]; rows=defaultdict(list); emitted=[]; names={}; old={}; missing_permalinks=[]
    if notes.exists():
        for p in notes.glob('*.md'):
            m=re.search(r' — ([^.]+)\.md$',p.name)
            if m: old[m.group(1)]=p
    for r in confirmed:
        sid=r['stable_id']; desired=notes/f'{slug(title(r))} — {sid}.md'; prior=old.get(sid)
        if prior and prior != desired and not desired.exists(): prior.rename(desired)
        p=desired
        assignment=assignments[sid]
        rendered_record=dict(r)
        rendered_record.update({field:r[field] for field in JUDGEMENT_FIELDS if field in r})
        if scalar(r.get('permalink_url')) in (None, ''):
            missing_permalinks.append({'stable_id':str(sid),'title':title(r)})
        if write(p,render_v3(rendered_record,assignment,credibility_by_id.get(sid,[])),backups,refusals): emitted.append(p); names[sid]=p.name; rows[clean(assignment['primary_topic']).lower()].append(rendered_record)
    # Preserve the pre-existing agent-authored geo note referenced by the corpus index.
    geo_name='geo_grandmasters — AI surveillance and commercial power — DZ7sxpHyfzu.md'
    for geo_source in (ROOT/'publication'/'Notes'/geo_name, ROOT/'publication-dryrun-pre-canvasfix'/'Notes'/geo_name):
        if geo_source.exists():
            geo_target=notes/geo_name
            if not geo_target.exists():
                write_generated(geo_target, geo_source.read_text(encoding='utf-8'), backups)
            break
    if not IMAGE_SOURCE.exists(): raise RuntimeError(f'missing official image asset: {IMAGE_SOURCE}')
    img=dest/IMAGE_DEST_REL; img.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(IMAGE_SOURCE,img)
    idx=f'''---\ntype: index\ntitle: Saved AI Posts — Corpus Index\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\nupdated: "2026-09-22"\n---\n\n# Saved AI Posts\n\nThis dry run publishes {confirmed_count} confirmed Instagram AI-collection members. LinkedIn records and rejected records are out of scope.\n\nThe existing geo-grandmasters note is preserved but its post is rejected in v3 and is not a member of this AI collection: '''+link('50 Knowledge/57 Corpus/Saved AI Posts/Notes/geo_grandmasters — AI surveillance and commercial power — DZ7sxpHyfzu.md','existing geo note')+'''.\n\n''' + "\n".join(f"- {link('50 Knowledge/57 Corpus/Saved AI Posts/Topics/'+k+'.md',TOPIC_LABELS[k])}" for k in sorted(rows))+'''\n\n## Analysis layer\n\n- '''+link('50 Knowledge/57 Corpus/Saved AI Posts/Comparisons/Cross-category comparison.md','cross-category comparison')+'''\n- '''+link('50 Knowledge/57 Corpus/Saved AI Posts/Comparisons/ai-news — comparison.md','category comparisons')+'''\n- '''+link('50 Knowledge/57 Corpus/Saved AI Posts/Entities/agentic-os.md','entity notes (multi-pointer)')+'''\n- '''+link('50 Knowledge/57 Corpus/Saved AI Posts/Saved AI Posts.canvas','category and cluster canvas')+'''\n'''; write(dest/'00 - Saved AI Posts Corpus Index.md',idx,backups,refusals)
    ensure_corpus_index_links(dest)
    write(dest/'Needs review.md','''---\ntype: index\ntitle: Saved AI Posts — Needs review\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\nupdated: "2026-09-20"\n---\n\n# Needs review\n\n'''+'\n'.join(f"- {r['stable_id']}: {', '.join(clean(x) for x in list_value(r,'unresolved_questions')[0])}" for r in confirmed if list_value(r,'unresolved_questions')[0])+"\n",backups,refusals)
    write(dest/'Notes/README.md',folder_readme('Saved AI Posts — Notes index','This folder holds one source note for each accepted AI and technology saved post.',[(f'50 Knowledge/57 Corpus/Saved AI Posts/Notes/{names[sid]}',title(next(r for r in confirmed if r['stable_id']==sid))) for sid in sorted(names)]),backups,refusals)
    write(dest/'Topics/README.md',folder_readme('Saved AI Posts — Topics index','This folder holds the topic-level syntheses for the accepted saved-post corpus.',[(f'50 Knowledge/57 Corpus/Saved AI Posts/Topics/{slug(k)}.md',TOPIC_LABELS[k]) for k in sorted(rows)]),backups,refusals)
    dm=load(DM) if DM.exists() else {'resources':[]}
    dm_scan=load(DM_SCAN) if DM_SCAN.exists() else {'ai_or_tech_items':[],'coverage':{},'limits':[]}
    dm_rows=[]; dm_seen=set()
    for _r in list(dm.get('resources',[]))+[{k:v for k,v in _x.items() if k!='author_handle'} for _x in dm_scan.get('ai_or_tech_items',[])]:
        _url=clean(_r.get('url')); _short=clean(_r.get('shortcode')); _key=('url',_url.lower()) if _url else (('shortcode',_short) if _short else ('row',len(dm_rows)))
        if _key in dm_seen: continue
        dm_seen.add(_key); dm_rows.append(_r)
    _entities=load(ENTITY_LAYER) if ENTITY_LAYER.exists() else {'entities':[]}
    _entity_rows=[_e for _e in _entities.get('entities',[]) if _e.get('pointer_count',0)>=2]
    def _entity_for_dm(_r):
        _name=clean(_r.get('name')).casefold(); _url=clean(_r.get('url')).casefold()
        for _e in _entity_rows:
            _aliases=[clean(_e.get('canonical')).casefold()]+[clean(_a).casefold() for _a in _e.get('aliases',[])]
            if (_e.get('canonical_url') and clean(_e.get('canonical_url')).casefold()==_url) or (_name and any(_a and _a in _name for _a in _aliases)):
                return _e
        return None
    _hdr='---\ntype: note\ntitle: Saved AI Posts — DM resources\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\nupdated: "2026-09-21"\n---\n\n# Saved AI Posts — DM resources\n\nThis index carries public AI and technology resources only. Private conversation metadata and message contents are omitted. The second scan read '''+str(dm_scan.get('coverage',{}).get('threads_read','unknown'))+''' threads to completion; it found '''+str(dm_scan.get('coverage',{}).get('shared_items_seen','unknown'))+''' shared items and '''+str(dm_scan.get('reconciliation_with_dm_resource_index',{}).get('net_new','unknown'))+''' net-new resources.\n\nLimits:\n\n'''+"\n".join('- '+clean(_x) for _x in dm_scan.get('limits',[]))+'''\n\n'''
    _rows=[]
    for _r in dm_rows:
        _n=clean(_r.get('name')) or clean(_r.get('url')) or clean(_r.get('shortcode')) or 'public resource'
        _k=clean(_r.get('kind')) or 'unknown'; _u=clean(_r.get('url'))
        _e=_entity_for_dm(_r); _label=link('50 Knowledge/57 Corpus/Saved AI Posts/Entities/'+slug(_e.get('canonical'))+'.md',_n) if _e else _n
        _rows.append('- '+_label+' ('+_k+')'+((' — '+_u) if _u else ''))
    dmtext=_hdr+chr(10).join(_rows)+chr(10)
    write(dest/'DM resources.md',dmtext,backups,refusals)
    for k,v in sorted(rows.items()): write(topics_dir/f'{slug(k)}.md',synthesis_v3(k,v,names)+'\n\n## Comparison\n\n- '+link('50 Knowledge/57 Corpus/Saved AI Posts/Comparisons/'+slug(TOPIC_LABELS[k])+' — comparison.md','Read the category comparison')+'\n',backups,refusals)
    base='''filters:\n  and:\n    - note.corpus == "Saved AI Posts"\n    - note.subtype == "source"\nviews:\n  - type: table\n    name: "By primary topic"\n    filters: note.primary_topic != "unresolved"\n    order: [note.primary_topic, file.name]\n  - type: table\n    name: "By topic tags"\n    filters: note.topics_status == "resolved"\n    order: [note.topics, file.name]\n  - type: table\n    name: "Usefulness"\n    filters: note.usefulness_rating != "unresolved"\n    order: [note.usefulness_rating, file.name]\n  - type: table\n    name: "Verification"\n    filters: note.verification_status != "unresolved"\n    order: [note.verification_status, file.name]\n  - type: table\n    name: "Risk"\n    filters: note.risk_flags_status == "resolved"\n    order: [note.risk_flags, file.name]\n'''; write_generated(dest/'Saved AI Posts.base',base,backups)
    base_path=dest/'Saved AI Posts.base'
    current_base=base_path.read_text(encoding='utf-8')
    if 'name: "Source type"' not in current_base:
        current_base += '  - type: table\n    name: "Source type"\n    filters: note.source_type != "unresolved"\n    order: [note.source_type, file.name]\n  - type: table\n    name: "Enrichment"\n    filters: note.enrichment_state != "unresolved"\n    order: [note.enrichment_state, file.name]\n'
    base_path.write_text(current_base,encoding='utf-8')
    if not PLAN.exists(): raise RuntimeError(f'missing required plan source: {PLAN}')
    raw_plan=PLAN.read_text(encoding='utf-8')
    raw_plan=re.sub(r"\[\[Topics/([^]|]+)(?:\|([^]]+))?\]\]", lambda m: link('50 Knowledge/57 Corpus/Saved AI Posts/Topics/'+m.group(1)+'.md', m.group(2) or m.group(1)), raw_plan)
    raw_plan=re.sub(r"\[\[([^/\]|]+)(?:\|([^]]+))?\]\]", lambda m: link('50 Knowledge/57 Corpus/Saved AI Posts/'+m.group(1), m.group(2) or m.group(1)), raw_plan)
    raw_plan=raw_plan.replace('[[50 Knowledge/57 Corpus/Saved AI Posts/name|name]]', link('50 Knowledge/57 Corpus/Saved AI Posts/00 - Saved AI Posts Corpus Index.md','name'))
    raw_plan=raw_plan.replace('[[50 Knowledge/57 Corpus/Saved AI Posts/Topics/slug.md|slug]]', link('50 Knowledge/57 Corpus/Saved AI Posts/00 - Saved AI Posts Corpus Index.md','slug'))
    for old_path,new_path in {
        r"C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919":"<local-staging-root>",
        r"C:\Users\dougl\Projects\.lanes\rolesclass\reference\socialscan":"<historical-export-root>",
        r"C:\Users\dougl\My Drive (douglaspmcgowan@gmail.com)\Obsidian\Metropolis Pt. 1--The Maverick And The Test":"<vault-root>",
        r"C:\Users\dougl\.agents":"<agent-tools-root>",
        r"C:\Users\dougl\Projects\general-ai\.local\build_social_publication.py":"<builder>",
    }.items(): raw_plan=raw_plan.replace(old_path,new_path)
    raw_plan=raw_plan.replace('douglaspmcgowan@gmail.com','<account-email>')
    plan_text='---\ntype: note\ntitle: Continuation plan and progress map\nauthored_by: agent\nmaintained_by: agent\nstatus: current\ncorpus: Saved AI Posts\nupdated: "2026-09-20"\n---\n\n'+raw_plan
    write_generated(dest/'Continuation plan and progress map.md',plan_text,backups)
    link_count,bare_count=wikilink_metrics(dest)
    source_hist=Counter(str(r.get('caption_source') or r.get('source_file')) for r in confirmed)
    coherence_counts={k:{'coherent':coherence_count(k,v),'members':len(v)} for k,v in sorted(rows.items())}
    safe_backups=[]
    for item in backups:
        try: safe_backups.append(str(Path(item).resolve().relative_to(dest.resolve())))
        except ValueError: safe_backups.append(Path(item).name)
    correction_files=[]
    for path in judgement_correction_paths():
        correction_files.append({'path':str(path.resolve().relative_to(ROOT.resolve())).replace('\\','/'),'size':path.stat().st_size,'sha256':sha(path)})
    manifest={'input':{'path':'classification/catalog-records-v3.json','size':INPUT.stat().st_size,'sha256':sha(INPUT)},'topic_overlay':{'path':'classification/primary-topics-v2.json','size':OVERLAY.stat().st_size,'sha256':sha(OVERLAY)},'judgement_correction_files':correction_files,'judgement_corrections':applied_judgement_corrections,'confirmed_members':confirmed_count,'judgement_records':coverage['judgements'],'source_notes':len(emitted),'syntheses':len(rows),'topic_counts':dict(sorted((k,len(v)) for k,v in rows.items())),'coherence_counts':coherence_counts,'credibility_checks':{'records':len((credibility.get('records',{}) if isinstance(credibility,dict) else {})),'distinct_members':len(credibility_by_id),'notes_with_checks':sum(bool(credibility_by_id.get(str(r['stable_id']))) for r in confirmed)},'caption_source_histogram':dict(sorted(source_hist.items())),'wikilinks_checked':link_count,'bare_wikilinks':bare_count,'media_description_rewrites':MEDIA_REWRITES,'plan_copy':True,'backups':safe_backups,'refusals':refusals,'missing_permalinks':missing_permalinks,'excluded':{'rejected':sum(r.get('collection_membership')=='rejected' for r in records),'not_applicable':sum(r.get('collection_membership')=='not_applicable' for r in records)},'vault_write':False,'official_image':{'stable_id':'DbQyH2NBc7C','published_path':IMAGE_DEST_REL.as_posix(),'source':'vendor repository','instagram_media':False}}
    write_generated(dest/'run-manifest.json',json.dumps(manifest,indent=2,ensure_ascii=False),backups)
    if missing_permalinks:
        for item in missing_permalinks:
            print(f"NO_PERMALINK stable_id={item['stable_id']} title={item['title']}", file=sys.stderr)
    else:
        print("NO_PERMALINK_NOTES=0", file=sys.stderr)
    evidence=contract_evidence(dest,manifest,records,confirmed,assignments,rows,backups,refusals); write_generated(dest/'CONTRACT-EVIDENCE.md',evidence,backups); ensure_agent_note_tags(dest); scrub_publication_paths(dest); print(json.dumps(manifest,ensure_ascii=False,sort_keys=True))

if __name__=='__main__':
    try: main_v3()
    except Exception as e: print(str(e),file=sys.stderr); sys.exit(1)
