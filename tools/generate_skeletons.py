#!/usr/bin/env python3
# tools/generate_skeletons.py
# Usage:
#   python tools/generate_skeletons.py --tree tree.json --design design/complete_design.json --responsibility responsibility_map.json --report reports/dry_run_report.json --agent copilot_agent_local --dry-run
#   python tools/generate_skeletons.py --tree tree.json --design design/complete_design.json --responsibility responsibility_map.json --report reports/generate_skeletons_report.json --agent copilot_agent_local --apply

import argparse
import json
import os
import shutil
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
    audit_dir = os.path.join("audit", "logs")
    os.makedirs(audit_dir, exist_ok=True)
    filename = f"{ts.replace(':','-')}_generate_skeletons.json"
    path = os.path.join(audit_dir, filename)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
    return path

def ensure_backup(path):
    if os.path.exists(path):
        bak = path + ".bak." + datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
        shutil.copy2(path, bak)
        return bak
    return None

def create_file(path, content, dry_run):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    if dry_run:
        return {"path": path, "action": "would_create"}
    if os.path.exists(path):
        return {"path": path, "action": "skipped_exists"}
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    return {"path": path, "action": "created"}

def generate_skeleton_for_file(file_entry):
    # file_entry is from design/complete_design.json
    file_path = file_entry["file"]
    classes = file_entry.get("classes", [])
    header = f"// Path: {file_path}\n// AUTO-GEN skeleton\n\n"
    body = ""
    # simple Dart skeleton if path ends with .dart, otherwise generic
    if file_path.endswith(".dart"):
        body += "import 'package:flutter/material.dart';\n\n"
        for cls in classes:
            cls_name = cls.get("name")
            body += f"class {cls_name} " + "{\n"
            for m in cls.get("methods", []):
                mname = m.get("name")
                args = ", ".join([f"{a.get('type')} {a.get('name')}" for a in m.get("args", [])])
                ret = m.get("return", "void")
                # Normalize return: if already Future<...> keep as is, else use ret directly inside Future<>
                if ret.startswith("Future"):
                    ret_decl = ret
                else:
                    ret_decl = f"{ret}"
                body += f"  Future<{ret_decl}> {mname}({args}) async " + "{\n"
                body += "    // TODO: implement\n    throw UnimplementedError();\n  }\n\n"
            body += "}\n\n"
    else:
        body += "// TODO: skeleton for " + file_path + "\n"
    return header + body

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tree", required=True)
    parser.add_argument("--design", required=True)
    parser.add_argument("--responsibility", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--agent", default="copilot_agent_local")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    tree = load_json(args.tree)
    design = load_json(args.design)
    responsibility = load_json(args.responsibility)

    # Build list of target files to generate: files in design that do not exist in repo
    repo_files = {f["path"] for f in tree.get("files", [])}
    to_generate = []
    for f in design.get("files", []):
        path = f["file"].replace('\\','/')
        if path not in repo_files:
            to_generate.append(f)

    results = []
    created_files = []
    backups = []
    for f in to_generate:
        file_path = f["file"].replace('\\','/')
        content = generate_skeleton_for_file(f)
        res = create_file(file_path, content, dry_run=args.dry_run or not args.apply)
        results.append(res)
        if res["action"] == "created":
            created_files.append(file_path)

    report = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "agent_id": args.agent,
        "design_file": args.design,
        "tree_file": args.tree,
        "responsibility_file": args.responsibility,
        "dry_run": args.dry_run and not args.apply,
        "to_generate_count": len(to_generate),
        "results": results
    }
    write_json(args.report, report)

    audit_path = make_audit_entry(args.agent, "generate_skeletons --apply" if args.apply else "generate_skeletons --dry-run", [r["path"] for r in results])
    print("Report written:", args.report)
    print("Audit log:", audit_path)
    if args.apply and created_files:
        print("Files created:", created_files)

if __name__ == "__main__":
    main()
