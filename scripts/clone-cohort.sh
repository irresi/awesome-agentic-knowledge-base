#!/usr/bin/env bash
# Clone or shallow-update every cohort repo into surveys/_clones/<slug>/
# so survey claims can be re-verified against current code.
#
# Each survey file at surveys/<org>__<repo>.md maps to GitHub
# https://github.com/<org>/<repo> — one survey per cohort entry.
#
# Usage:
#   scripts/clone-cohort.sh                    # all 46
#   scripts/clone-cohort.sh <slug>             # one, e.g. infiniflow__ragflow
#   PARALLEL=8 scripts/clone-cohort.sh         # concurrent clones (default 4)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CLONES="$ROOT/surveys/_clones"
PARALLEL=${PARALLEL:-4}

mkdir -p "$CLONES"

clone_or_update() {
    local slug=$1
    local url_path=${slug//__//}
    local url="https://github.com/${url_path}.git"
    local dir="$CLONES/$slug"

    if [[ -d "$dir/.git" ]]; then
        printf '→ %-40s update\n' "$url_path"
        if ! git -C "$dir" fetch --depth 1 origin HEAD --quiet 2>&1; then
            printf '  ✗ fetch failed for %s\n' "$url_path" >&2
            return 1
        fi
        git -C "$dir" reset --hard FETCH_HEAD --quiet
    else
        printf '→ %-40s clone\n' "$url_path"
        if ! git clone --depth 1 --single-branch "$url" "$dir" --quiet 2>&1; then
            printf '  ✗ clone failed for %s\n' "$url_path" >&2
            return 1
        fi
    fi
}
export -f clone_or_update
export CLONES

slugs() {
    if [[ $# -gt 0 ]]; then
        printf '%s\n' "$@"
    else
        for f in "$ROOT/surveys/"*.md; do
            local name
            name=$(basename "$f" .md)
            [[ "$name" == "README" ]] && continue
            printf '%s\n' "$name"
        done
    fi
}

if (( PARALLEL > 1 )); then
    slugs "$@" | xargs -n1 -P"$PARALLEL" -I{} bash -c 'clone_or_update "$@"' _ {}
else
    slugs "$@" | while read -r slug; do
        clone_or_update "$slug"
    done
fi

echo
echo "Done. $(ls "$CLONES" | wc -l | tr -d ' ') repos in $CLONES"
