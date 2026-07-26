"""
engine.py
Core forensics engine for MetaGhost.

All actual work (exiftool invocation, risk classification, report
generation, scrubbing) lives here so it can be driven by the Flask API
(server.py) or, in principle, straight from a script. Nothing in this
file talks HTTP - it only touches the filesystem and shells out to
exiftool.
"""

import json
import os
import re
import shutil
import subprocess
import time
import uuid
from datetime import datetime
from pathlib import Path

# --- Paths -------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent
REPORT_DIR = BASE_DIR / "reports"
CLEAN_DIR = BASE_DIR / "clean_output"
BACKUP_DIR = BASE_DIR / "backups"
HISTORY_FILE = BASE_DIR / "history.json"

for d in (REPORT_DIR, CLEAN_DIR, BACKUP_DIR):
    d.mkdir(parents=True, exist_ok=True)

# --- Risk classification -------------------------------------------------
# Ordered most-severe first. Each tag name is matched case-insensitively
# against the exiftool tag key.

RISK_RULES = [
    ("critical", ["GPS", "Location", "GPSLatitude", "GPSLongitude", "GPSPosition"]),
    ("high", ["Creator", "Author", "Owner", "SerialNumber", "LensSerialNumber",
              "InternalSerialNumber", "CameraSerialNumber", "Email", "Artist",
              "By-line", "ContactInfo"]),
    ("medium", ["Software", "OperatingSystem", "HostComputer", "Model",
                "Make", "LensModel", "DeviceModel", "Copyright",
                "DocumentID", "OriginalDocumentID", "InstanceID",
                "XMPToolkit", "HistorySoftwareAgent"]),
    ("low", ["DateTime", "CreateDate", "ModifyDate", "OffsetTime",
             "TimeZone", "SubSecTime"]),
]

LEVEL_WEIGHT = {"critical": 25, "high": 10, "medium": 4, "low": 1, "none": 0}
LEVEL_ORDER = ["critical", "high", "medium", "low", "none"]
LEVEL_LABEL = {
    "critical": "CRITICAL",
    "high": "HIGH",
    "medium": "MEDIUM",
    "low": "LOW",
    "none": "CLEAN",
}


class MetaGhostError(Exception):
    pass


def check_exiftool():
    """Return (installed: bool, version: str|None)."""
    path = shutil.which("exiftool")
    if not path:
        return False, None
    try:
        out = subprocess.run(["exiftool", "-ver"], capture_output=True, text=True, timeout=5)
        return True, out.stdout.strip()
    except Exception:
        return True, None


def _classify(tag_key: str) -> str:
    tag_lower = tag_key.lower()
    for level, patterns in RISK_RULES:
        for p in patterns:
            if p.lower() in tag_lower:
                return level
    return "none"


def _run_exiftool_json(path: str) -> list:
    """Run exiftool -j -G1 on a single file and return the parsed dict list."""
    if not os.path.isfile(path):
        raise MetaGhostError(f"File not found: {path}")
    try:
        proc = subprocess.run(
            ["exiftool", "-j", "-G1", "-a", "-u", path],
            capture_output=True, text=True, timeout=30,
        )
    except FileNotFoundError:
        raise MetaGhostError("exiftool is not installed or not on PATH.")
    except subprocess.TimeoutExpired:
        raise MetaGhostError("exiftool timed out analyzing this file.")

    if proc.returncode != 0 and not proc.stdout.strip():
        raise MetaGhostError(proc.stderr.strip() or "exiftool failed to read this file.")

    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        raise MetaGhostError("Could not parse exiftool output.")
    return data[0] if data else {}


def analyze(path: str) -> dict:
    """Deep analysis: pulls every tag exiftool can find, classifies each
    by privacy risk, and returns a structured summary plus an HTML
    report written to disk."""
    raw = _run_exiftool_json(path)
    filename = os.path.basename(path)

    tags = []
    counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "none": 0}
    for key, value in raw.items():
        if key in ("SourceFile",):
            continue
        group, _, tag_name = key.partition(":")
        if not tag_name:
            tag_name, group = group, ""
        level = _classify(key)
        counts[level] += 1
        tags.append({
            "group": group or "File",
            "tag": tag_name,
            "value": str(value),
            "level": level,
        })

    # Sort so the scariest tags float to the top of the table.
    tags.sort(key=lambda t: LEVEL_ORDER.index(t["level"]))

    score = sum(LEVEL_WEIGHT[t["level"]] for t in tags)
    if counts["critical"] > 0:
        overall = "critical"
    elif counts["high"] > 0:
        overall = "high"
    elif counts["medium"] > 0:
        overall = "medium"
    elif counts["low"] > 0:
        overall = "low"
    else:
        overall = "none"

    report_id = uuid.uuid4().hex[:10]
    report_name = f"{Path(filename).stem}_{report_id}.html"
    report_path = REPORT_DIR / report_name
    _write_html_report(report_path, filename, tags, counts, overall, score)

    result = {
        "filename": filename,
        "path": str(path),
        "tag_count": len(tags),
        "risk_counts": counts,
        "risk_level": overall,
        "risk_label": LEVEL_LABEL[overall],
        "risk_score": score,
        "tags": tags,
        "report_file": report_name,
        "report_path": str(report_path),
        "timestamp": datetime.now().isoformat(timespec="seconds"),
    }
    _log_history("analyze", filename, overall, str(report_path))
    return result


def _write_html_report(report_path: Path, filename: str, tags: list, counts: dict, overall: str, score: int):
    level_colors = {
        "critical": "#ff4d6d", "high": "#e6b45c", "medium": "#4facfe",
        "low": "#7fd88f", "none": "#5b6577",
    }
    rows = []
    for t in tags:
        color = level_colors[t["level"]]
        badge = f'<span class="badge" style="color:{color};border-color:{color}">{t["level"].upper()}</span>' if t["level"] != "none" else ""
        val = (t["value"][:400] + "…") if len(t["value"]) > 400 else t["value"]
        val = (val.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))
        rows.append(
            f'<tr><td class="grp">{t["group"]}</td><td class="tagname">{t["tag"]}</td>'
            f'<td class="val">{val}</td><td>{badge}</td></tr>'
        )

    overall_color = level_colors[overall]
    html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>MetaGhost Report - {filename}</title>
<style>
  :root {{ --bg:#0a0e1a; --panel:#0f1524; --panel2:#141b2e; --line:#1e2740;
           --cyan:#38bdf8; --text:#c9d4e3; --dim:#7b8699; }}
  *{{box-sizing:border-box;}}
  body{{background:var(--bg);color:var(--text);font-family:'JetBrains Mono',Consolas,monospace;
        padding:32px;margin:0;}}
  .wrap{{max-width:1100px;margin:0 auto;}}
  h1{{font-size:20px;letter-spacing:1px;margin-bottom:4px;color:#e2e8f0;}}
  .sub{{color:var(--dim);font-size:12px;margin-bottom:24px;}}
  .summary{{display:flex;gap:16px;margin-bottom:24px;flex-wrap:wrap;}}
  .card{{background:var(--panel);border:1px solid var(--line);border-radius:6px;
         padding:16px 20px;min-width:140px;}}
  .card .n{{font-size:26px;font-weight:700;}}
  .card .l{{font-size:11px;letter-spacing:1px;color:var(--dim);margin-top:4px;}}
  .overall{{border:1px solid {overall_color};background:rgba(255,255,255,0.02);
            border-radius:6px;padding:16px 20px;margin-bottom:24px;}}
  .overall .n{{font-size:26px;font-weight:700;color:{overall_color};}}
  table{{width:100%;border-collapse:collapse;font-size:12px;background:var(--panel);
         border:1px solid var(--line);border-radius:6px;overflow:hidden;}}
  th{{text-align:left;background:var(--panel2);color:var(--dim);letter-spacing:1px;
      font-size:10px;padding:10px 12px;border-bottom:1px solid var(--line);}}
  td{{padding:8px 12px;border-bottom:1px solid var(--line);vertical-align:top;}}
  tr:hover td{{background:rgba(56,189,248,0.05);}}
  .grp{{color:var(--dim);}}
  .tagname{{color:#e2e8f0;font-weight:600;}}
  .val{{word-break:break-word;max-width:420px;}}
  .badge{{border:1px solid;border-radius:10px;padding:1px 8px;font-size:10px;font-weight:700;}}
  footer{{margin-top:24px;color:var(--dim);font-size:11px;}}
</style></head>
<body><div class="wrap">
  <h1>MetaGhost Forensic Report</h1>
  <div class="sub">{filename} &middot; generated {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</div>

  <div class="overall">
    <div class="n">{LEVEL_LABEL[overall]} RISK</div>
    <div class="l" style="color:var(--dim);font-size:11px;">Composite exposure score: {score}</div>
  </div>

  <div class="summary">
    <div class="card"><div class="n" style="color:#ff4d6d">{counts['critical']}</div><div class="l">CRITICAL</div></div>
    <div class="card"><div class="n" style="color:#e6b45c">{counts['high']}</div><div class="l">HIGH</div></div>
    <div class="card"><div class="n" style="color:#4facfe">{counts['medium']}</div><div class="l">MEDIUM</div></div>
    <div class="card"><div class="n" style="color:#7fd88f">{counts['low']}</div><div class="l">LOW</div></div>
    <div class="card"><div class="n" style="color:#5b6577">{sum(counts.values())}</div><div class="l">TOTAL TAGS</div></div>
  </div>

  <table>
    <tr><th>Group</th><th>Tag</th><th>Value</th><th>Risk</th></tr>
    {''.join(rows)}
  </table>

  <footer>Generated by MetaGhost v4.0 &middot; HackOps Academy &middot; 100% offline analysis</footer>
</div></body></html>"""
    report_path.write_text(html, encoding="utf-8")


def gps(path: str) -> dict:
    """Extract GPS data with as much forensic context as exiftool has:
    coordinates, altitude, direction, and capture timestamp."""
    if not os.path.isfile(path):
        raise MetaGhostError(f"File not found: {path}")

    fields = [
        "-GPSLatitude", "-GPSLongitude", "-GPSLatitudeRef", "-GPSLongitudeRef",
        "-GPSAltitude", "-GPSImgDirection", "-GPSDateTime", "-GPSDateStamp",
        "-GPSTimeStamp", "-GPSSpeed", "-GPSSpeedRef",
    ]
    try:
        proc = subprocess.run(
            ["exiftool", "-c", "%.6f", "-j"] + fields + [path],
            capture_output=True, text=True, timeout=20,
        )
    except FileNotFoundError:
        raise MetaGhostError("exiftool is not installed or not on PATH.")

    try:
        data = json.loads(proc.stdout)[0]
    except (json.JSONDecodeError, IndexError):
        data = {}

    lat_raw = data.get("GPSLatitude")
    lon_raw = data.get("GPSLongitude")

    if lat_raw is None or lon_raw is None:
        _log_history("gps", os.path.basename(path), "none", None)
        return {"found": False, "filename": os.path.basename(path)}

    def to_float(v):
        try:
            return float(str(v).split()[0])
        except (ValueError, IndexError):
            return None

    lat = to_float(lat_raw)
    lon = to_float(lon_raw)
    if data.get("GPSLatitudeRef", "").lower().startswith("s") and lat is not None:
        lat = -lat
    if data.get("GPSLongitudeRef", "").lower().startswith("w") and lon is not None:
        lon = -lon

    result = {
        "found": lat is not None and lon is not None,
        "filename": os.path.basename(path),
        "latitude": lat,
        "longitude": lon,
        "altitude": data.get("GPSAltitude"),
        "direction": data.get("GPSImgDirection"),
        "datetime": data.get("GPSDateTime") or data.get("GPSDateStamp"),
        "speed": data.get("GPSSpeed"),
        "map_link": f"https://www.google.com/maps?q={lat},{lon}" if lat is not None and lon is not None else None,
    }
    _log_history("gps", result["filename"], "critical" if result["found"] else "none", None)
    return result


def scrub(path: str) -> dict:
    """Strip all metadata from a single file, keeping a timestamped
    backup of the original."""
    if not os.path.isfile(path):
        raise MetaGhostError(f"File not found: {path}")

    filename = os.path.basename(path)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup_path = BACKUP_DIR / f"{stamp}_{filename}.bak"
    output_path = CLEAN_DIR / f"clean_{filename}"

    shutil.copy2(path, backup_path)

    try:
        proc = subprocess.run(
            ["exiftool", "-all=", "-o", str(output_path), path],
            capture_output=True, text=True, timeout=30,
        )
    except FileNotFoundError:
        raise MetaGhostError("exiftool is not installed or not on PATH.")

    if not output_path.exists():
        raise MetaGhostError(proc.stderr.strip() or "Scrubbing failed - check file permissions.")

    _log_history("scrub", filename, "cleaned", str(output_path))
    return {
        "filename": filename,
        "output_path": str(output_path),
        "backup_path": str(backup_path),
    }


def bulk_scrub(dir_path: str) -> dict:
    """Scrub every regular file in a directory (non-recursive)."""
    if not os.path.isdir(dir_path):
        raise MetaGhostError(f"Directory not found: {dir_path}")

    out_dir = CLEAN_DIR / "bulk_clean"
    out_dir.mkdir(parents=True, exist_ok=True)

    results = []
    for entry in sorted(os.listdir(dir_path)):
        full = os.path.join(dir_path, entry)
        if not os.path.isfile(full):
            continue
        out_path = out_dir / entry
        try:
            proc = subprocess.run(
                ["exiftool", "-all=", "-o", str(out_path), full],
                capture_output=True, text=True, timeout=30,
            )
            ok = out_path.exists()
        except FileNotFoundError:
            raise MetaGhostError("exiftool is not installed or not on PATH.")
        results.append({
            "filename": entry,
            "ok": ok,
            "error": None if ok else (proc.stderr.strip()[:200] or "failed"),
        })

    cleaned = sum(1 for r in results if r["ok"])
    _log_history("bulk_scrub", os.path.basename(dir_path.rstrip("/")), "cleaned", str(out_dir))
    return {
        "directory": dir_path,
        "output_dir": str(out_dir),
        "total": len(results),
        "cleaned": cleaned,
        "results": results,
    }


# --- History log ---------------------------------------------------------

def _log_history(op: str, filename: str, risk_level: str, result_path):
    entry = {
        "id": uuid.uuid4().hex[:8],
        "ts": datetime.now().isoformat(timespec="seconds"),
        "op": op,
        "filename": filename,
        "risk_level": risk_level,
        "result_path": result_path,
    }
    history = _read_history()
    history.insert(0, entry)
    history = history[:500]
    HISTORY_FILE.write_text(json.dumps(history, indent=2), encoding="utf-8")


def _read_history():
    if not HISTORY_FILE.exists():
        return []
    try:
        return json.loads(HISTORY_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []


def get_history():
    return _read_history()


def clear_history():
    HISTORY_FILE.write_text("[]", encoding="utf-8")
    return {"ok": True}


def list_reports():
    items = []
    for f in sorted(REPORT_DIR.glob("*.html"), key=lambda p: p.stat().st_mtime, reverse=True):
        items.append({
            "name": f.name,
            "path": str(f),
            "size": f.stat().st_size,
            "mtime": datetime.fromtimestamp(f.stat().st_mtime).isoformat(timespec="seconds"),
        })
    return items
