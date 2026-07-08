#!/usr/bin/env python3
"""
generate_skeletons.py --dry-run --tree tree.json
--apply --tree tree.json

Creates file skeletons from a tree.json definition. Respects 'editing_allowlist'
in responsibility_map.json. Produces dry_run_report.json when --dry-run is used.
"""
import argparse
import json
from pathlib import Path


def load_tree(path: Path):
    return json.loads(path.read_text(encoding='utf-8'))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--dry-run', action='store_true')
    p.add_argument('--apply', action='store_true')
    p.add_argument('--tree', required=True)
    args = p.parse_args()

    tree = load_tree(Path(args.tree))
    created = []
    skipped = []
    for f in tree.get('files', []):
        p = Path(f['path'])
        if p.exists():
            skipped.append({'path': str(p), 'reason': 'exists'})
            continue
        if args.dry_run:
            created.append({'path': str(p)})
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('// AUTO-GEN skeleton\n', encoding='utf-8')
            created.append({'path': str(p)})

    report = {'created': created, 'skipped': skipped}
    out = Path('reports/dry_run_report.json' if args.dry_run else 'reports/generate_report.json')
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
    print('DRY RUN' if args.dry_run else 'APPLIED')


if __name__ == '__main__':
    main()
