#!/usr/bin/env bash
# Print the slug of the cohort survey with the oldest audit footer date.
# Audit footer format: `*Audit YYYY-MM-DD: ...*` or `*Re-audit ... YYYY-MM-DD ...*`.
# Surveys with no audit date are treated as date 0000-00-00 (highest priority).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)

for f in "$ROOT/surveys/"*.md; do
    name=$(basename "$f" .md)
    [[ "$name" == "README" ]] && continue
    # Most recent date inside any Audit / Re-audit footer line
    latest=$(grep -oE '\*?(Re-)?[Aa]udit[^*]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$f" 2>/dev/null \
              | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
              | sort -r | head -1)
    [[ -z "$latest" ]] && latest="0000-00-00"
    printf '%s %s\n' "$latest" "$name"
done | sort | head -1 | awk '{print $2}'
