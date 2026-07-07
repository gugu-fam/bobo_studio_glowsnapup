import sys
from pathlib import Path
p=Path('reports/dart_analyze_report.txt')
if not p.exists():
    print('MISSING')
    sys.exit(1)
raw=p.read_bytes()
text=None
for enc in ('utf-8','utf-16','utf-16-le','utf-16-be','latin-1'):
    try:
        text=raw.decode(enc)
        break
    except Exception:
        pass
if text is None:
    print('DECODE_FAIL')
    sys.exit(2)
# write utf8
Path('reports/dart_analyze_report_utf8.txt').write_text(text,encoding='utf-8')
# extract warnings/errors
lines=[l for l in text.splitlines() if 'warning' in l.lower() or 'error' in l.lower() or ':' in l]
Path('reports/dart_analyze_top_warnings.txt').write_text('\n'.join(lines[:200]),encoding='utf-8')
print('OK')
