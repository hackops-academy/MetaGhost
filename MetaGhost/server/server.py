"""
server.py
Local API layer for MetaGhost.

Runs as its own process on 127.0.0.1. The HUD (Electron) talks to it
straight from the Electron main process, so CORS doesn't come into it -
but we still scope binding to localhost only, since this process shells
out to exiftool against whatever path it's given.

Run with:
    python3 server.py
"""

import sys
from pathlib import Path

from flask import Flask, jsonify, request, send_file

sys.path.insert(0, str(Path(__file__).resolve().parent))
import engine  # noqa: E402

app = Flask(__name__)


def err(message, status=400):
    return jsonify({"ok": False, "error": message}), status


@app.get("/api/status")
def status():
    installed, version = engine.check_exiftool()
    return jsonify({
        "ok": True,
        "exiftool_installed": installed,
        "exiftool_version": version,
        "version": "4.0",
    })


@app.post("/api/analyze")
def analyze():
    data = request.get_json(silent=True) or {}
    path = data.get("path", "").strip()
    if not path:
        return err("No file path provided.")
    try:
        result = engine.analyze(path)
        return jsonify({"ok": True, "data": result})
    except engine.MetaGhostError as e:
        return err(str(e))
    except Exception as e:
        return err(f"Unexpected error: {e}", 500)


@app.post("/api/gps")
def gps():
    data = request.get_json(silent=True) or {}
    path = data.get("path", "").strip()
    if not path:
        return err("No file path provided.")
    try:
        result = engine.gps(path)
        return jsonify({"ok": True, "data": result})
    except engine.MetaGhostError as e:
        return err(str(e))
    except Exception as e:
        return err(f"Unexpected error: {e}", 500)


@app.post("/api/scrub")
def scrub():
    data = request.get_json(silent=True) or {}
    path = data.get("path", "").strip()
    if not path:
        return err("No file path provided.")
    try:
        result = engine.scrub(path)
        return jsonify({"ok": True, "data": result})
    except engine.MetaGhostError as e:
        return err(str(e))
    except Exception as e:
        return err(f"Unexpected error: {e}", 500)


@app.post("/api/bulk")
def bulk():
    data = request.get_json(silent=True) or {}
    dirpath = data.get("directory", "").strip()
    if not dirpath:
        return err("No directory provided.")
    try:
        result = engine.bulk_scrub(dirpath)
        return jsonify({"ok": True, "data": result})
    except engine.MetaGhostError as e:
        return err(str(e))
    except Exception as e:
        return err(f"Unexpected error: {e}", 500)


@app.get("/api/reports")
def reports():
    return jsonify({"ok": True, "data": engine.list_reports()})


@app.get("/api/reports/<path:name>")
def report_file(name):
    target = engine.REPORT_DIR / name
    if not target.exists() or target.parent != engine.REPORT_DIR:
        return err("Report not found.", 404)
    return send_file(target)


@app.get("/api/history")
def history():
    return jsonify({"ok": True, "data": engine.get_history()})


@app.post("/api/history/clear")
def history_clear():
    return jsonify({"ok": True, "data": engine.clear_history()})


if __name__ == "__main__":
    installed, version = engine.check_exiftool()
    if not installed:
        print("[!] WARNING: exiftool was not found on PATH.")
        print("    Install it first, e.g.:")
        print("      Debian/Ubuntu/Kali : sudo apt install libimage-exiftool-perl")
        print("      Termux             : pkg install exiftool")
        print("      macOS              : brew install exiftool")
    else:
        print(f"[+] exiftool {version} detected.")
    print("[+] MetaGhost API starting on http://127.0.0.1:8077")
    app.run(host="127.0.0.1", port=8077, debug=False)
