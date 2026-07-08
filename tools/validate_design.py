#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
    import jsonschema
except Exception:
    print("Missing dependencies: run 'pip install pyyaml jsonschema' or use requirements.txt", file=sys.stderr)
    sys.exit(2)


def load_yaml_or_json(path: Path):
    text = path.read_text(encoding='utf-8')
    try:
        return json.loads(text)
    except Exception:
        return yaml.safe_load(text)


def main():
    p = argparse.ArgumentParser(description='Validate design YAML/JSON against meta_schema.json')
    p.add_argument('--input', '-i', required=True)
    p.add_argument('--schema', '-s', default=str(Path(__file__).parent.parent / 'design' / 'meta_schema.json'))
    p.add_argument('--output', '-o', default='design/validation_report.json')
    args = p.parse_args()

    input_path = Path(args.input)
    schema_path = Path(args.schema)
    output_path = Path(args.output)

    if not input_path.exists():
        print(f'Input file not found: {input_path}', file=sys.stderr)
        sys.exit(2)
    if not schema_path.exists():
        print(f'Schema file not found: {schema_path}', file=sys.stderr)
        sys.exit(2)

    design = load_yaml_or_json(input_path)
    schema = json.loads(schema_path.read_text(encoding='utf-8'))

    validator = jsonschema.Draft7Validator(schema)
    errors = []
    for e in sorted(validator.iter_errors(design), key=lambda x: x.path):
        errors.append({
            'message': e.message,
            'path': list(e.path),
            'schema_path': list(e.schema_path)
        })

    report = {
        'input': str(input_path),
        'schema': str(schema_path),
        'valid': len(errors) == 0,
        'errors': errors
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')

    if errors:
        print('VALIDATION FAILED: see', output_path)
        sys.exit(1)
    else:
        # write validated_design.json for downstream steps
        validated = Path('design/validated_design.json')
        validated.write_text(json.dumps(design, indent=2, ensure_ascii=False), encoding='utf-8')
        print('VALIDATION PASSED: validated_design.json written')
        sys.exit(0)


if __name__ == '__main__':
    main()
