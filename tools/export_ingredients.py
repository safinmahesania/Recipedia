"""Exports canonical ingredient names, so the importers can tell new from known.

Uses Supabase's REST API rather than psql. psql is not installed on Windows by
default and is a heavy thing to require for one SELECT — the REST endpoint is
already there and needs no client at all.

    set SUPABASE_URL=https://YOURPROJECT.supabase.co
    set SUPABASE_ANON_KEY=eyJ...
    python tools/export_ingredients.py

Reads with the anon key. If RLS blocks anonymous reads on ingredients, use the
service_role key from the same dashboard page — it is only ever used here, on
your machine, and never goes near the app.
"""

import json
import os
import pathlib
import sys
import urllib.parse
import urllib.request

OUT = pathlib.Path("out")


def fetch(url, key):
    req = urllib.request.Request(url, headers={
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Accept": "application/json",
    })
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())


def main():
    base = os.environ.get("SUPABASE_URL", "").rstrip("/")
    key = os.environ.get("SUPABASE_ANON_KEY") or os.environ.get("SUPABASE_KEY")
    if not base or not key:
        sys.exit("Set SUPABASE_URL and SUPABASE_ANON_KEY first.\n"
                 "Both are on Supabase -> Project Settings -> API.")

    OUT.mkdir(exist_ok=True)
    rows, offset = [], 0
    while True:
        # PostgREST caps a page at 1000; the catalogue is smaller than that but
        # paging costs nothing and stops this breaking if it grows.
        url = (f"{base}/rest/v1/ingredients?select=name,aliases"
               f"&order=name&limit=1000&offset={offset}")
        page = fetch(url, key)
        rows += page
        if len(page) < 1000:
            break
        offset += 1000

    names = [r["name"].strip().lower() for r in rows if r.get("name")]

    # Aliases count as known too, or the importer will "discover" pyaz as a new
    # ingredient when onion already covers it.
    aliases = []
    for r in rows:
        for a in (r.get("aliases") or []):
            if a:
                aliases.append(a.strip().lower())

    known = sorted(set(names) | set(aliases))
    (OUT / "existing_ingredients.txt").write_text("\n".join(known), encoding="utf-8")

    print(f"  ingredients : {len(names)}")
    print(f"  aliases     : {len(set(aliases))}")
    print(f"  known total : {len(known)}  -> out/existing_ingredients.txt")


if __name__ == "__main__":
    main()
