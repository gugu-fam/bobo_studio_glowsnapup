#!/usr/bin/env python3
"""
generate_skeletons.py --dry-run --tree tree.json
--apply --tree tree.json

Creates file skeletons from a tree.json definition. Respects 'editing_allowlist'
in responsibility_map.json. Produces dry_run_report.json when --dry-run is used.
"""
import argparse
import json
import shutil
import datetime
from pathlib import Path


def load_tree(path: Path):
    return json.loads(path.read_text(encoding='utf-8'))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--dry-run', action='store_true', help='Perform a dry run')
    p.add_argument('--apply', action='store_true', help='Apply file creation')
    p.add_argument('--backup', action='store_true', help='Create backups for existing files')
    p.add_argument('--strict', action='store_true', help='Abort if any target file already exists')
    p.add_argument('--tree', required=True, help='Path to tree.json')
    args = p.parse_args()

    tree = load_tree(Path(args.tree))
    planned = []
    skipped = []
    for f in tree.get('files', []):
        p = Path(f['path'])
        if p.exists():
            skipped.append({'path': str(p), 'reason': 'exists'})
        else:
            planned.append(p)

    # helper: load allowlist from responsibility_map.json if present
    allowlist = None
    resp_map = Path('responsibility_map.json')
    if resp_map.exists():
        try:
            rm = json.loads(resp_map.read_text(encoding='utf-8'))
            allowlist = rm.get('editing_allowlist')
        except Exception:
            allowlist = None

    # Before applying, perform strict/backup checks and allowlist validation
    targets = planned
    def is_allowed(path: Path):
        if not allowlist:
            return True
        s = str(path).replace('\\', '/')
        for a in allowlist:
            if s.startswith(a.rstrip('/')):
                return True
        return False
    if not args.dry_run and args.apply:
        # check allowlist: filter out disallowed targets but warn
        disallowed = [str(t) for t in targets if not is_allowed(t)]
        if disallowed:
            print('WARNING: skipping targets outside editing_allowlist:', disallowed)
            targets = [t for t in targets if is_allowed(t)]

        # check existing files among remaining targets (shouldn't exist because planned excluded existing)
        existing = [t for t in targets if t.exists()]
        if existing:
            if args.strict:
                print('ABORT: existing files would be overwritten:', [str(x) for x in existing])
                return
            if args.backup:
                ts = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
                backup_dir = Path('.skeleton_backups') / ts
                for p in existing:
                    backup_dir.mkdir(parents=True, exist_ok=True)
                    target = backup_dir / p.name
                    shutil.copy2(p, target)
                    print(f'BACKED UP {p} -> {target}')

        # perform creation for remaining targets
        created = []
        for p in targets:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('// AUTO-GEN skeleton\n', encoding='utf-8')
            created.append({'path': str(p)})
    else:
        created = [{'path': str(p)} for p in planned]

    report = {'created': created, 'skipped': skipped}
    out = Path('reports/dry_run_report.json' if args.dry_run else 'reports/generate_report.json')
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
    print('DRY RUN' if args.dry_run else 'APPLIED')


if __name__ == '__main__':
    main()
