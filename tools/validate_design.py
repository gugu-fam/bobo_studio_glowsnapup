#!/usr/bin/env python3
# tools/validate_design.py
# Usage:
#   python tools/validate_design.py --input design/spec.yaml --schema design/meta_schema.json --out design/validation_report.json --validated design/validated_design.json

import argparse
import json
import sys
import os
import datetime
from jsonschema import Draft7Validator
import yaml

def load_yaml(path):
    with open(path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)

def make_audit_entry(agent_id, action, input_path, result_summary, out_path):
    ts = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    entry = {
        "timestamp": ts,
        "agent_id": agent_id,
        "action": action,
        "input": input_path,
        "result_summary": result_summary,
        "out_path": out_path
    }
    audit_dir = os.path.join("audit", "logs")
    os.makedirs(audit_dir, exist_ok=True)
    filename = f"{ts.replace(':','-')}_validate_design.json"
    path = os.path.join(audit_dir, filename)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
    return path

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="design/spec.yaml")
    parser.add_argument("--schema", required=True, help="design/meta_schema.json")
    parser.add_argument("--out", required=True, help="design/validation_report.json")
    parser.add_argument("--validated", required=True, help="design/validated_design.json")
    parser.add_argument("--agent", default="copilot_agent_local", help="agent id for audit")
    args = parser.parse_args()

    try:
        spec = load_yaml(args.input)
    except Exception as e:
        report = {"valid": False, "error": f"Failed to load YAML: {str(e)}"}
        write_json(args.out, report)
        print("ERROR: failed to load input YAML", file=sys.stderr)
        sys.exit(2)

    try:
        schema = load_json(args.schema)
    except Exception as e:
        report = {"valid": False, "error": f"Failed to load schema JSON: {str(e)}"}
        write_json(args.out, report)
        print("ERROR: failed to load schema JSON", file=sys.stderr)
        sys.exit(2)

    validator = Draft7Validator(schema)
    errors = sorted(validator.iter_errors(spec), key=lambda e: e.path)

    if errors:
        details = []
        for e in errors:
            details.append({
                "message": e.message,
                "path": list(e.path),
                "schema_path": list(e.schema_path)
            })
        report = {
            "valid": False,
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
            "errors": details
        }
        write_json(args.out, report)
        audit_path = make_audit_entry(args.agent, "validate_design_failed", args.input, {"valid": False, "errors_count": len(details)}, args.out)
        print(f"Validation FAILED. Report written to {args.out}. Audit: {audit_path}")
        sys.exit(3)
    else:
        summary = {
            "valid": True,
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
            "files_defined": len(spec.get("files", [])) if isinstance(spec, dict) else None,
            "classes_defined": sum(len(f.get("classes", [])) for f in spec.get("files", [])) if isinstance(spec, dict) and spec.get("files") else None
        }
        write_json(args.out, {"valid": True, "timestamp": summary["timestamp"], "notes": "Schema validation passed."})
        validated = {
            "validated": True,
            "timestamp": summary["timestamp"],
            "agent_id": args.agent,
            "input_spec": args.input,
            "schema_version": schema.get("version", "unknown"),
            "summary": summary
        }
        write_json(args.validated, validated)
        audit_path = make_audit_entry(args.agent, "validate_design_pass", args.input, {"valid": True}, args.validated)
        print(f"Validation PASSED. Validated file: {args.validated}. Audit: {audit_path}")
        sys.exit(0)

if __name__ == "__main__":
    main()
