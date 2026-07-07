#!/usr/bin/env python3
# tools/generate_tree.py
# Usage:
#   python tools/generate_tree.py --design design/complete_design.json --out tree.json --md tree.md --report reports/tree_generation_report.json --agent copilot_agent_local
import argparse
import json
import os
import datetime
from pathlib import Path

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def write_json(path, obj):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)

def write_md(path, content):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def scan_repo_files():
    # Prefer git ls-files if available
    try:
        import subprocess
        out = subprocess.check_output(['git','ls-files'], universal_newlines=True)
        files = [line.strip() for line in out.splitlines() if line.strip()]
        return files
    except Exception:
        # Fallback: walk current directory excluding .git
        files = []
        for p in Path('.').rglob('*'):
            if p.is_file() and '.git' not in p.parts:
                files.append(str(p).replace('\\','/'))
        return files

def build_tree(design, repo_files):
    root = os.path.abspath('.').replace('\\','/')
    folders = {}
    files_meta = []
    # Map design files for presence check
    design_files = {f['file'] for f in design.get('files', [])}
    for f in repo_files:
        parts = f.split('/')
        # record folder nodes
        for i in range(1, len(parts)):
            folder = '/'.join(parts[:i])
            folders.setdefault(folder, set())
            folders[folder].add(parts[i])
        files_meta.append({"path": f, "in_design": f in design_files})
    # Build folder list
    folder_list = []
    for folder, children in sorted(folders.items()):
        folder_list.append({"path": folder, "children_count": len(children)})
    tree = {"root": root, "folders": folder_list, "files": files_meta}
    return tree

def make_audit_entry(agent_id, action, files_changed):
    ts = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    entry = {
        "timestamp": ts,
        "agent_id": agent_id,
        "action": action,
        "files_changed": files_changed
    }
    audit_dir = os.path.join("audit","logs")
    os.makedirs(audit_dir, exist_ok=True)
    filename = f"{ts.replace(':','-')}_generate_tree.json"
    path = os.path.join(audit_dir, filename)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
    return path

def render_md(tree):
    lines = []
    lines.append(f"# Project Tree\n\n**root**: {tree.get('root')}\n\n---\n")
    lines.append("## Folders\n")
    for f in tree.get('folders', []):
        lines.append(f"- {f['path']} ({f['children_count']} children)")
    lines.append("\n## Files\n")
    for file in tree.get('files', []):
        lines.append(f"- {file['path']}  {'(in design)' if file.get('in_design') else ''}")
    return '\n'.join(lines)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--design", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--md", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--agent", default="copilot_agent_local")
    args = parser.parse_args()

    design = load_json(args.design)
    repo_files = scan_repo_files()
    tree = build_tree(design, repo_files)
    write_json(args.out, tree)
    md = render_md(tree)
    write_md(args.md, md)

    report = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "agent_id": args.agent,
        "design_file": args.design,
        "out_file": args.out,
        "md_file": args.md,
        "files_count": len(tree.get("files", [])),
        "folders_count": len(tree.get("folders", []))
    }
    write_json(args.report, report)
    audit_path = make_audit_entry(args.agent, "generate_tree --apply", [args.out, args.md])
    print("Tree generated:", args.out)
    print("MD generated:", args.md)
    print("Report:", args.report)
    print("Audit log:", audit_path)

if __name__ == "__main__":
    main()
