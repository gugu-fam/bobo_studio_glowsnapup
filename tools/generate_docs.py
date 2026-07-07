#!/usr/bin/env python3
# tools/generate_docs.py
# Usage:
#   python tools/generate_docs.py --design design/complete_design.json --out_dir docs --report reports/docs_generation_report.json --dry-run
#   python tools/generate_docs.py --design design/complete_design.json --out_dir docs --report reports/docs_generation_report.json --apply

import argparse
import json
import os
import datetime
import textwrap

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def write_file(path, content, dry_run=False):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    if dry_run:
        print(f"[dry-run] would write: {path}")
        return
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def make_audit_entry(agent_id, action, files_changed):
    ts = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    entry = {
        "timestamp": ts,
        "agent_id": agent_id,
        "action": action,
        "files_changed": files_changed
    }
    audit_dir = os.path.join("audit", "logs")
    os.makedirs(audit_dir, exist_ok=True)
    filename = f"{ts.replace(':','-')}_generate_docs.json"
    path = os.path.join(audit_dir, filename)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
    return path

def render_doc_header(title, agent_id, design_ref):
    ts = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    return textwrap.dedent(f"""\
    # {title}

    **generated_at**: {ts}  
    **agent_id**: {agent_id}  
    **design_ref**: {design_ref}

    ---
    """)

def render_overview(design):
    title = "Project Overview"
    header = render_doc_header(title, AGENT, DESIGN)
    summary = design.get("meta", {}).get("project", "") + " - " + design.get("meta", {}).get("version", "")
    body = f"## Summary\n\n{summary}\n\n## Files\n\n"
    for f in design.get("files", [])[:50]:
        body += f"- {f.get('file')}\n"
    return header + body

def render_requirements(design):
    title = "Requirements"
    header = render_doc_header(title, AGENT, DESIGN)
    body = "## Functional Requirements\n\n"
    for f in design.get("files", []):
        for cls in f.get("classes", []):
            for m in cls.get("methods", []):
                body += f"- **{cls.get('name')}.{m.get('name')}**: {m.get('responsibilities','')}\n"
    return header + body

def render_template_map():
    return {
        "overview.md": render_overview,
        "requirements.md": render_requirements,
        # Additional templates can be added here
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--design", required=True)
    parser.add_argument("--out_dir", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--agent", default="copilot_agent_local")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    global AGENT, DESIGN
    AGENT = args.agent
    DESIGN = args.design

    design = load_json(args.design)

    templates = render_template_map()
    files_written = []
    for fname, renderer in templates.items():
        content = renderer(design)
        out_path = os.path.join(args.out_dir, fname)
        write_file(out_path, content, dry_run=args.dry_run or not args.apply)
        files_written.append(out_path)

    report = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "agent_id": args.agent,
        "design_file": args.design,
        "out_dir": args.out_dir,
        "files_generated": files_written,
        "dry_run": args.dry_run and not args.apply
    }
    os.makedirs(os.path.dirname(args.report) or '.', exist_ok=True)
    with open(args.report, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    audit_path = make_audit_entry(args.agent, "generate_docs --apply" if args.apply else "generate_docs --dry-run", files_written)
    print("Report:", args.report)
    print("Audit log:", audit_path)

if __name__ == "__main__":
    main()
