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
# Must equal the project's PRODUCTION BRANCH (Cloudflare dashboard -> Pages ->
# open3dpp -> Settings -> Builds & deployments). A deploy to any other branch
# is a Preview deployment, and the custom domain serves production only — so
# the site uploads fine and open3dpp.org still returns "Deployment Not Found".
BRANCH="${OPEN3DPP_BRANCH:-main}"
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
  --branch "$BRANCH" \
  --commit-dirty=true \
  --commit-hash "$HEAD_SHA" \
  --commit-message "Open3DPP deploy $HEAD_SHA"

say "Deployment environment"
# A Preview deployment never reaches the custom domain. Say so plainly rather
# than letting the operator debug a 404 that is really a branch mismatch.
ENV_LINE="$(npx wrangler pages deployment list --project-name "$PROJECT" 2>/dev/null | grep -m1 -E 'Production|Preview' || true)"
if printf '%s' "$ENV_LINE" | grep -q Production; then
  echo "Production — this deployment is what the custom domain serves."
else
  echo "PREVIEW, not Production. The custom domain will keep returning"
  echo "\"Deployment Not Found\" until a deployment lands on the production branch."
  echo
  echo "  Branch deployed: $BRANCH"
  echo "  Fix: Cloudflare dashboard -> Pages -> $PROJECT -> Settings ->"
  echo "       Builds & deployments -> Production branch. Either set it to"
  echo "       '$BRANCH', or re-run with OPEN3DPP_BRANCH=<that branch>."
fi

say "Verify the identifier answers"
# A deploy that does not make $id resolve has not done its job. This is the
# same condition the release gate checks before it will let the docs claim the
# schema resolves.
# Pipe straight into python: writing to /tmp and reading it back broke on
# Windows, where Git Bash's /tmp and the Windows python's /tmp are different
# directories, so the check reported a live site as unreachable.
if curl -fsS --max-time 20 "$SCHEMA_ID" | python -c "
import json, sys
want = sys.argv[1]
try:
    got = json.load(sys.stdin).get('\$id')
except Exception:
    sys.exit(1)
sys.exit(0 if got == want else 1)
" "$SCHEMA_ID"; then
  echo "LIVE: $SCHEMA_ID returns its own schema"
  echo
  echo "The docs may now state that the \$id resolves; the release gate will"
  echo "verify that claim by fetching it."
else
  echo "NOT YET: $SCHEMA_ID did not return the schema."
  echo "  - is the deployment above Production? a Preview never reaches the domain"
  echo "  - is open3dpp.org attached to Pages project '$PROJECT'?"
  echo "The upload itself succeeded; the site is reachable on its *.pages.dev URL."
fi
