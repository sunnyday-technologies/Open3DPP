#!/usr/bin/env bash
# Deploy open3dpp.org to Cloudflare Pages via wrangler.
#
#   bash scripts/deploy.sh            # build, verify, deploy, check it answers
#   bash scripts/deploy.sh --dry-run  # build and verify only; no upload
#
# Auth comes from your own `wrangler login` — no tokens live in this repo.
#
# ONE-TIME, in the Cloudflare dashboard: attach the custom domain open3dpp.org
# to the Pages project `open3dpp`. Without it the deploy succeeds but only
# answers on open3dpp.pages.dev, and every published $id still 404s.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$ROOT/.cloudflare/pages/open3dpp"
PROJECT="open3dpp"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

say "Build"
python "$ROOT/scripts/build_site.py" "$SITE"

say "Schema identity"
# The whole point of the site: every $id must equal the URL it will be served
# from. build_site.py enforces this; restate the current one for the operator.
SCHEMA_ID="$(python - "$SITE" <<'PY'
import json, sys, pathlib
p = sorted(pathlib.Path(sys.argv[1], "schemas").rglob("*.json"))[-1]
print(json.loads(p.read_text(encoding="utf-8"))["$id"])
PY
)"
echo "$SCHEMA_ID"

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "Dry run: staged $(find "$SITE" -type f | wc -l) files; nothing uploaded."
  exit 0
fi

say "Deploy"
HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD)"
DEPLOY_SITE="$SITE"
if command -v wslpath >/dev/null 2>&1; then
  DEPLOY_SITE="$(wslpath -w "$SITE")"
fi
npx wrangler pages deploy "$DEPLOY_SITE" \
  --project-name "$PROJECT" \
  --branch main \
  --commit-dirty=true \
  --commit-hash "$HEAD_SHA" \
  --commit-message "Open3DPP deploy $HEAD_SHA"

say "Verify the identifier answers"
# A deploy that does not make $id resolve has not done its job. This is the
# same condition the release gate checks before it will let the docs claim the
# schema resolves.
if curl -fsS --max-time 20 "$SCHEMA_ID" -o /tmp/open3dpp-live.json 2>/dev/null &&
   python -c "
import json,sys
want=sys.argv[1]
got=json.load(open('/tmp/open3dpp-live.json',encoding='utf-8')).get('\$id')
sys.exit(0 if got==want else 1)
" "$SCHEMA_ID"; then
  echo "LIVE: $SCHEMA_ID returns its own schema"
  echo
  echo "The docs may now state that the \$id resolves. Re-run the release gate"
  echo "to confirm, then update the wording."
else
  echo "NOT YET: $SCHEMA_ID did not return the schema."
  echo "  - custom domain open3dpp.org attached to Pages project '$PROJECT'?"
  echo "  - DNS propagated? (open3dpp.pages.dev should already answer)"
  echo "The deploy itself succeeded; only the custom-domain mapping is missing."
fi
