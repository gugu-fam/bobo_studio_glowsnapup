#!/usr/bin/env python3
# tools/generate_skeleton_code.py
# Usage:
#   python tools/generate_skeleton_code.py --design design/complete_design.json --responsibility responsibility_map.json --tree tree.json --report reports/skeletons_dry_run_report.json --agent copilot_agent_local --dry-run
#   python tools/generate_skeleton_code.py --design design/complete_design.json --responsibility responsibility_map.json --tree tree.json --report reports/skeletons_generation_report.json --agent copilot_agent_local --apply

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
    filename = f"{ts.replace(':','-')}_generate_skeletons_code.json"
    path = os.path.join(audit_dir, filename)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
    return path

def is_editable(path, responsibility):
    perms = responsibility.get("editing_permissions", [])
    for p in perms:
        if path.startswith(p.rstrip('/')):
            return True
    return False

def dart_class_skeleton(cls):
    name = cls.get("name")
    methods = cls.get("methods", [])
    lines = []
    lines.append(f"class {name} " + "{")
    for m in methods:
        mname = m.get("name")
        args = m.get("args", [])
        arg_list = ", ".join([f"{a.get('type')} {a.get('name')}" for a in args])
        ret = m.get("return", "void")
        if "Future" in ret or ret != "void":
            # attempt to extract inner type
            inner = ret
            if ret.startswith("Future<") and ret.endswith(">"):
                inner = ret[7:-1]
            signature = f"  Future<{inner}> {mname}({arg_list}) async " + "{"
            lines.append(signature)
            lines.append("    // TODO: implement")
            lines.append("    throw UnimplementedError();")
            lines.append("  }")
        else:
            signature = f"  {ret} {mname}({arg_list}) " + "{"
            lines.append(signature)
            lines.append("    // TODO: implement")
            lines.append("    throw UnimplementedError();")
            lines.append("  }")
        lines.append("")
    lines.append("}")
    return "\n".join(lines)

def generate_file_content(file_entry):
    file_path = file_entry["file"]
    header = f"// Path: {file_path}\n// AUTO-GEN skeleton\n\n"
    if file_path.endswith(".dart"):
        content = header + "import 'package:flutter/material.dart';\n\n"
        for cls in file_entry.get("classes", []):
            content += dart_class_skeleton(cls) + "\n\n"
        return content
    else:
        return header + "// TODO: skeleton for " + file_path + "\n"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--design", required=True)
    parser.add_argument("--responsibility", required=True)
    parser.add_argument("--tree", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--agent", default="copilot_agent_local")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    design = load_json(args.design)
    responsibility = load_json(args.responsibility)
    tree = load_json(args.tree)

    repo_files = {f["path"].replace('\\','/') for f in tree.get("files", [])}
    to_generate = []
    for f in design.get("files", []):
        path = f["file"].replace('\\','/')
        if path not in repo_files:
            if not is_editable(path, responsibility):
                continue
            to_generate.append(f)

    results = []
    created = []
    for f in to_generate:
        path = f["file"].replace('\\','/')
        content = generate_file_content(f)
        os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
        if args.dry_run or not args.apply:
            results.append({"path": path, "action": "would_create"})
        else:
            if os.path.exists(path):
                results.append({"path": path, "action": "skipped_exists"})
            else:
                with open(path, 'w', encoding='utf-8') as fh:
                    fh.write(content)
                results.append({"path": path, "action": "created"})
                created.append(path)

    report = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "agent_id": args.agent,
        "design_file": args.design,
        "responsibility_file": args.responsibility,
        "tree_file": args.tree,
        "dry_run": args.dry_run and not args.apply,
        "to_generate_count": len(to_generate),
        "results": results,
        "created_files": created
    }
    write_json(args.report, report)
    audit_path = make_audit_entry(args.agent, "generate_skeletons_code --apply" if args.apply else "generate_skeletons_code --dry-run", [r["path"] for r in results])
    print("Report:", args.report)
    print("Audit log:", audit_path)

    if args.apply:
        try:
            import subprocess
            subprocess.run(["dart", "analyze"], check=False)
        except Exception:
            pass

if __name__ == "__main__":
    main()
