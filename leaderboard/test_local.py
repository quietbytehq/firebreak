#!/usr/bin/env python3
"""Local wrangler dev tests. Does not contact firebreak.quietbytehq.uk."""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

BASE = os.environ.get("FIREBREAK_SCORES_URL", "http://127.0.0.1:8787")
ADMIN_KEY = os.environ["ADMIN_KEY"]
ROOT = os.environ.get("FIREBREAK_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
GODOT = os.environ.get("GODOT", "godot")
failures = 0


def report(ok: bool, label: str, detail="") -> None:
    global failures
    if ok:
        print("PASS", label)
    else:
        failures += 1
        print("FAIL", label, detail)


def req(method: str, path: str, body=None):
    data = None if body is None else json.dumps(body).encode()
    headers = {"content-type": "application/json"} if body is not None else {}
    request = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=8) as res:
            raw = res.read().decode()
            ctype = res.headers.get("content-type", "")
            parsed = json.loads(raw) if "json" in ctype or raw[:1] == "{" else raw
            return res.status, parsed, raw
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            parsed = json.loads(raw)
        except Exception:
            parsed = raw
        return e.code, parsed, raw


def submit(name, score, mode="campaign", version="0.3.3", stages=1):
    return req("POST", "/api/submit", {
        "name": name, "score": score, "mode": mode, "version": version, "stages": stages,
    })


def main() -> int:
    # Valid score, including an integer-valued float.
    code, data, _ = submit("ACE", 6230.0)
    report(code == 200 and data.get("ok") is True, "valid score 6230.0 accepted", f"{code} {data}")
    code, data, _ = req("GET", "/api/top")
    top = data.get("scores") or []
    report(
        code == 200 and data.get("ok") and top and top[0]["name"] == "ACE" and top[0]["score"] == 6230,
        "valid score appears on the board",
        f"{code} {data}",
    )

    for label, body in [
        ("below minimum", {"name": "LOW", "score": 1990, "mode": "campaign", "version": "0.3.3", "stages": 1}),
        ("above maximum", {"name": "HIGH", "score": 5000010, "mode": "campaign", "version": "0.3.3", "stages": 12}),
        ("not a multiple of 10", {"name": "STEP", "score": 2005, "mode": "campaign", "version": "0.3.3", "stages": 1}),
        ("non-integer", {"name": "FRAC", "score": 2010.1, "mode": "campaign", "version": "0.3.3", "stages": 1}),
    ]:
        code, data, _ = req("POST", "/api/submit", body)
        report(code == 400 and data.get("ok") is False, label + " refused", f"{code} {data}")

    for label, name in [
        ("blocked name FUCK", "FUCK"),
        ("leetspeak 5H1T", "5H1T"),
        ("leetspeak FUC K", "FUC K"),
        ("leetspeak P0RN", "P0RN"),
    ]:
        code, data, _ = submit(name, 2500)
        report(code == 400 and data.get("error") == "name not allowed", label + " refused", f"{code} {data}")

    code, data, _ = submit("ACE", 2500, mode="river_village")
    report(code == 400 and data.get("error") == "unknown mode", "unknown mode refused", f"{code} {data}")

    code, data, _ = submit("ACE", 2500, stages=0)
    report(code == 400, "stages 0 refused", f"{code} {data}")
    code, data, _ = submit("ACE", 2500, stages=13)
    report(code == 400, "stages 13 refused", f"{code} {data}")
    code, data, _ = submit("ACE", 40010, stages=1)
    report(code == 400, "score over 40000 times stages refused", f"{code} {data}")
    code, data, _ = submit("SCOUT", 40010, stages=2)
    report(code == 200 and data.get("ok") is True, "40010 with 2 stages accepted", f"{code} {data}")

    # Game-side post before the rate-limit slots are filled (2 used so far: ACE, SCOUT).
    env = os.environ.copy()
    env["FIREBREAK_SCORES_URL"] = BASE + "/api/submit"
    user = tempfile.mkdtemp(prefix="fb-post-")
    env["XDG_DATA_HOME"] = user
    env["XDG_CONFIG_HOME"] = os.path.join(user, "config")
    proc = subprocess.run(
        [GODOT, "--headless", "--path", ROOT, "--script", "tests/post_dev_score.gd"],
        env=env, capture_output=True, text=True, timeout=45,
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    print(out.strip())
    report(proc.returncode == 0 and "GAME_POST 200" in out, "game-side headless post to local wrangler accepted", f"rc={proc.returncode} {out[-500:]}")
    code, data, _ = req("GET", "/api/top")
    names = [s["name"] for s in data.get("scores", [])]
    report("DEVBOT" in names, "game-side post appears on the board", names)

    # Markup is stripped on submit; a raw HTML name inserted in the DB is escaped on the admin page.
    code, data, _ = submit("AB<script>X", 2600)
    report(code == 200 and data.get("ok") is True, "name with markup characters is accepted after stripping", f"{code} {data}")
    code, data, _ = req("GET", "/api/top")
    names = [s["name"] for s in data.get("scores", [])]
    report("AB<script>X" not in names and "ABSCRIPTX" in names, "markup is stripped from the stored name", names)

    subprocess.check_call(
        [
            "npx", "wrangler", "d1", "execute", "firebreak-scores", "--local", "--yes",
            "--command",
            "INSERT INTO scores (name, score, table_id, version, stages, ip_hash, created_at) VALUES ('<img src=x>', 2700, 'campaign', '0.3.3', 1, 'test', 1);",
        ],
        stdout=subprocess.DEVNULL,
    )
    code, parsed, raw = req("GET", f"/admin?key={ADMIN_KEY}")
    report(
        code == 200 and "&lt;img src=x&gt;" in raw and "<img src=x>" not in raw,
        "admin page escapes markup in a name",
        f"{code} {raw[:240]}",
    )

    code, parsed, raw = req("GET", "/admin")
    report(code == 404 and "Not found" in raw, "admin without key returns not found", f"{code} {raw}")
    code, parsed, raw = req("GET", "/admin?key=wrong")
    report(code == 404 and "Not found" in raw, "admin with a wrong key returns not found", f"{code} {raw}")

    code, parsed, raw = req("GET", f"/admin?key={ADMIN_KEY}")
    row = None
    for m in re.finditer(r"<tr><td>(\d+)</td><td>([^<]*)</td>", raw):
        if m.group(2) == "&lt;img src=x&gt;":
            row = m.group(1)
            break
    report(row is not None, "admin lists the escaped injection row", raw[:300])
    if row:
        delete = urllib.request.Request(BASE + f"/admin/delete?key={ADMIN_KEY}&id={row}", method="GET")
        try:
            urllib.request.urlopen(delete, timeout=8)
        except urllib.error.HTTPError:
            pass
        code, parsed, raw = req("GET", f"/admin?key={ADMIN_KEY}")
        report("&lt;img src=x&gt;" not in raw and "<img src=x>" not in raw, "deleted injection row is gone from admin", raw[:300])

    # Rate limit is per address: 4 posts so far (ACE, SCOUT, DEVBOT, ABSX). Two more should pass, the 7th fails.
    ok_codes = []
    for i in range(2):
        code, data, _ = submit(f"RATE{i}", 3000 + i * 10)
        ok_codes.append(code)
    report(ok_codes == [200, 200], "posts 5 and 6 from this address accepted", ok_codes)
    code, data, _ = submit("RATE2", 3040)
    report(code == 429 and data.get("error") == "too many scores, try later", "7th post in an hour is rate-limited", f"{code} {data}")

    code, parsed, raw = req("GET", "/")
    report(
        code == 200 and "FIREBREAK" in raw and "innerHTML" not in raw and "textContent" in raw,
        "themed page uses textContent, not innerHTML",
        f"{code}",
    )

    print("Local worker tests:", "FAILED" if failures else "all passed", f"({failures} failures)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
