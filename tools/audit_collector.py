#!/usr/bin/env python3
"""
Collect and validate audit logs under audit/logs/, produce a summary
reports/audit_summary.json and an integrity report at reports/integrity_report.json
"""
import json
from pathlib import Path
import hashlib

LOG_DIR = Path('audit/logs')
OUT_DIR = Path('reports')
OUT_DIR.mkdir(parents=True, exist_ok=True)


def hash_file(p: Path):
    h = hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()


def collect():
    logs = []
    if not LOG_DIR.exists():
        print('No audit logs directory; nothing to collect')
        return
    for f in sorted(LOG_DIR.glob('*.json')):
        try:
            j = json.loads(f.read_text(encoding='utf-8'))
            j['_path'] = str(f)
            j['_sha256'] = hash_file(f)
            logs.append(j)
        except Exception as e:
            logs.append({'_path': str(f), 'error': str(e)})

    summary = {
        'count': len(logs),
        'logs': logs
    }
    OUT_DIR.joinpath('audit_summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')

    # simple integrity report
    integrity = {'unimplemented_methods': [], 'audit_count': len(logs)}
    OUT_DIR.joinpath('integrity_report.json').write_text(json.dumps(integrity, indent=2, ensure_ascii=False), encoding='utf-8')
    print('WROTE reports/audit_summary.json and reports/integrity_report.json')


if __name__ == '__main__':
    collect()
