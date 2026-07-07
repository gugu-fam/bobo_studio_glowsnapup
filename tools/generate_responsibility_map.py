#!/usr/bin/env python3
# tools/generate_responsibility_map.py
# Usage:
#   python tools/generate_responsibility_map.py --design design/complete_design.json --tree tree.json --out responsibility_map.json --report reports/responsibility_report.json --agent copilot_agent_local

import argparse
import json
import os
import datetime
from collections import defaultdict

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def write_json(path, obj):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)

def make_audit_entry(agent_id, action, files_changed, out_path):
    ts = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    entry = {
        "timestamp": ts,
        "agent_id": agent_id,
        "action": action,
        "files_changed": files_changed
    }
    audit_dir = os.path.join("audit", "logs")
    os.makedirs(audit_dir, exist_ok=True)
    filename = f"{ts.replace(':','-')}_responsibility_map.json"
    path = os.path.join(audit_dir, filename)
    write_json(path, entry)
    return path

def build_responsibility_map(design, tree):
    map_out = {"generated_at": datetime.datetime.utcnow().isoformat() + "Z", "files": []}
    file_index = {f["file"]: f for f in design.get("files", [])}
    # For each file in design, extract classes and methods
    for file_entry in design.get("files", []):
        file_path = file_entry["file"]
        classes = []
        for cls in file_entry.get("classes", []):
            methods = []
            for m in cls.get("methods", []):
                methods.append({
                    "name": m.get("name"),
                    "args": m.get("args", []),
                    "return": m.get("return"),
                    "exceptions": m.get("exceptions", []),
                    "responsibilities": m.get("responsibilities", "")
                })
            classes.append({
                "name": cls.get("name"),
                "methods": methods,
                "state_responsibility": cls.get("state-responsibility", [])
            })
        map_out["files"].append({
            "file": file_path,
            "exists_in_tree": any(node.get("path")==file_path for node in tree.get("files", [])) if tree else False,
            "classes": classes
        })
    # Build editing permission list: allow only lib/features/* and lib/core/*
    editable = []
    for node in tree.get("folders", []):
        p = node.get("path")
        if p and (p.startswith("lib/features") or p.startswith("lib/core")):
            editable.append(p)
    map_out["editing_permissions"] = editable or ["lib/features", "lib/core"]
    # Build dependency skeleton (placeholder: empty edges)
    map_out["dependencies"] = {"edges": [], "nodes_count": len(map_out["files"]) }
    return map_out

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--design", required=True)
    parser.add_argument("--tree", required=False, default=None)
    parser.add_argument("--out", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--agent", default="copilot_agent_local")
    args = parser.parse_args()

    design = load_json(args.design)
    tree = load_json(args.tree) if args.tree and os.path.exists(args.tree) else {"root": ".", "folders": [], "files": []}

    responsibility_map = build_responsibility_map(design, tree)
    write_json(args.out, responsibility_map)

    report = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "agent_id": args.agent,
        "design_file": args.design,
        "tree_file": args.tree,
        "out_file": args.out,
        "files_processed": len(responsibility_map["files"]),
        "editing_permissions_count": len(responsibility_map["editing_permissions"])
    }
    write_json(args.report, report)

    audit_path = make_audit_entry(args.agent, "generate_responsibility_map --apply", [args.out], args.report)
    print("Responsibility map generated:", args.out)
    print("Report written:", args.report)
    print("Audit log:", audit_path)

if __name__ == "__main__":
    main()
