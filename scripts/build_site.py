"""Build the web-only publish directory for open3dpp.org.

Run:  python scripts/build_site.py [publish_dir]

The site exists for one job: make the schema $id resolve. A record declares
schema_version 0.1.0 and names its schema
    https://open3dpp.org/schemas/core/v0.1.0/open3dpp-record.schema.json
which is exactly the repo path schemas/core/v0.1.0/... — so copying schemas/
verbatim makes every published identifier dereference to the same bytes this
repository holds. The $id/served-path check below is the one that matters: a
site that deploys but serves schemas at a different path still 404s every
identifier we have published.

Allowlist, not denylist: only the files named here can reach the deploy, and
every tripwire aborts the build rather than shipping something unexpected.
"""
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / ".cloudflare/pages/open3dpp"
HOST = "https://open3dpp.org"
MAX_BYTES = 2 * 1024 * 1024

ROOT_FILES = (
    "index.html", "404.html",
    "robots.txt", "sitemap.xml", "llms.txt", "_headers",
    "README.md", "Open3DPP_SCHEMA.md", "FIELDS.md", "CHANGELOG.md",
    "CONTRIBUTING.md", "SECURITY.md", "CITATION.cff", "LICENSE", "NOTICE",
)
PUBLIC_DIRS = ("schemas", "examples", "research")
BLOCKED = ("scripts", ".github", ".git", ".cloudflare", "node_modules")
SECRET_PATTERNS = (
    r"CLOUDFLARE_API_TOKEN\s*[:=]\s*\S",
    r"ghp_[A-Za-z0-9]{20,}",
    r"AKIA[0-9A-Z]{16}",
    r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
)
TEXT_SUFFIXES = {".md", ".json", ".txt", ".html", ".cff", ".toml", ".csv",
                 ".xml", ".fdm_material", ""}


def fail(msg: str) -> None:
    raise SystemExit("BUILD FAILED: %s" % msg)


def main() -> int:
    out = OUT.resolve()
    if ROOT not in out.parents and out != ROOT:
        fail("refusing to write outside the project root: %s" % out)
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    for rel in ROOT_FILES:
        src = ROOT / rel
        if not src.is_file():
            fail("missing public file: %s" % rel)
        shutil.copy2(src, out / rel)
    for rel in PUBLIC_DIRS:
        src = ROOT / rel
        if not src.is_dir():
            fail("missing public directory: %s" % rel)
        shutil.copytree(src, out / rel)

    files = [p for p in out.rglob("*") if p.is_file()]

    for name in BLOCKED:
        if (out / name).exists():
            fail("blocked path reached the publish dir: %s" % name)

    for p in files:
        if p.stat().st_size > MAX_BYTES:
            fail("oversized file (%d bytes): %s" % (p.stat().st_size, p))

    for p in files:
        if p.suffix.lower() not in TEXT_SUFFIXES:
            continue
        body = p.read_text(encoding="utf-8", errors="replace")
        for pat in SECRET_PATTERNS:
            if re.search(pat, body):
                fail("secret-looking string in %s (pattern %s)" % (p, pat))

    schemas = sorted((out / "schemas").rglob("*.json"))
    if not schemas:
        fail("no schema files reached the publish dir")
    for s in schemas:
        doc = json.loads(s.read_text(encoding="utf-8"))
        sid = doc.get("$id")
        if not sid:
            fail("schema without an $id: %s" % s)
        expected = "%s/%s" % (HOST, s.relative_to(out).as_posix())
        if sid != expected:
            fail("$id does not match the path it would be served from:\n"
                 "  $id      %s\n  would be %s" % (sid, expected))

    print("publish dir: %s" % out)
    print("  %d files, %d schema(s), all $id values match their served path"
          % (len(files), len(schemas)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
