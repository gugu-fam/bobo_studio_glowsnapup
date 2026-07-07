#!/usr/bin/env python3
# tools/run_integrity_checks.py
# Usage:
#   python tools/run_integrity_checks.py --design design/complete_design.json --tree tree.json --responsibility responsibility_map.json --out reports/integrity_report.json --agent copilot_agent_local

import argparse
import json
import os
import datetime
import subprocess
from pathlib import Path

def load_json(p):
    with open(p,'r',encoding='utf-8') as f:
        return json.load(f)

def write_json(p,obj):
    os.makedirs(os.path.dirname(p) or '.', exist_ok=True)
    with open(p,'w',encoding='utf-8') as f:
        json.dump(obj,f,indent=2,ensure_ascii=False)

def make_audit(agent,action,files_changed):
    ts = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    entry = {"timestamp":ts,"agent_id":agent,"action":action,"files_changed":files_changed}
    audit_dir = os.path.join("audit","logs")
    os.makedirs(audit_dir,exist_ok=True)
    fname = f"{ts.replace(':','-')}_integrity_check.json"
    path = os.path.join(audit_dir,fname)
    with open(path,'w',encoding='utf-8') as f:
        json.dump(entry,f,indent=2,ensure_ascii=False)
    return path

def find_unimplemented_methods(design, repo_files):
    missing = []
    for f in design.get("files",[]):
        path = f["file"].replace('\\','/')
        if not os.path.exists(path):
            missing.append({"file":path,"reason":"file_missing"})
            continue
        text = Path(path).read_text(encoding='utf-8')
        for cls in f.get("classes",[]):
            for m in cls.get("methods",[]):
                name = m.get("name")
                # heuristic: if UnimplementedError or 'TODO' present near method name, mark as unimplemented
                if name not in text or ("UnimplementedError" in text and name in text) or ("TODO" in text and name in text):
                    missing.append({"file":path,"class":cls.get("name"),"method":name,"status":"likely_unimplemented"})
    return missing

def detect_circular_dependencies(tree):
    # Placeholder: return empty list for now
    return []

def check_api_contracts(design):
    mismatches = []
    for api in design.get("api_contracts",[]):
        if not api.get("request_schema") or not api.get("response_schema"):
            mismatches.append({"api":api.get("name"),"issue":"missing_schema"})
    return mismatches

def run_dart_analyze():
    try:
        res = subprocess.run(["dart","analyze"], capture_output=True, text=True, check=False)
        return {"rc":res.returncode,"stdout":res.stdout,"stderr":res.stderr}
    except Exception as e:
        return {"rc":-1,"error":str(e)}

def run_custom_checks(design,tree,responsibility):
    repo_files = tree.get("files",[])
    unimplemented = find_unimplemented_methods(design, repo_files)
    cycles = detect_circular_dependencies(tree)
    api_mismatch = check_api_contracts(design)
    return {"unimplemented_methods":unimplemented,"cycles":cycles,"api_mismatches":api_mismatch}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--design", required=True)
    parser.add_argument("--tree", required=True)
    parser.add_argument("--responsibility", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--agent", default="copilot_agent_local")
    args = parser.parse_args()

    design = load_json(args.design)
    tree = load_json(args.tree)
    responsibility = load_json(args.responsibility)

    checks = run_custom_checks(design,tree,responsibility)
    dart = run_dart_analyze()

    report = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "agent_id": args.agent,
        "design_file": args.design,
        "tree_file": args.tree,
        "responsibility_file": args.responsibility,
        "checks": checks,
        "dart_analyze": {"rc":dart.get("rc"), "summary": (dart.get("stdout")[:1000] if dart.get("stdout") else ""), "stderr": (dart.get("stderr")[:1000] if dart.get("stderr") else "")}
    }

    write_json(args.out, report)
    audit_path = make_audit(args.agent, "run_integrity_checks --apply", [args.out])
    print("Integrity report written:", args.out)
    print("Audit log:", audit_path)

if __name__ == "__main__":
    main()
