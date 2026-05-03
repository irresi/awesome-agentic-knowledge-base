# Maintenance scripts

## `clone-cohort.sh` — local clone of every cohort repo

Clones (or updates) every entry in [`surveys/`](../surveys/) into
`surveys/_clones/<slug>/` so survey claims can be re-verified against
current code. Each clone is shallow (`--depth 1`, single branch) — total
disk usage is roughly 5–10 GB for the full cohort.

The path `surveys/_clones/` is gitignored (see `.gitignore`); these
clones are local research material, not part of the published map.

### Usage

```bash
# All 46 repos, 4 parallel workers
scripts/clone-cohort.sh

# Single repo (slug = filename of surveys/<slug>.md)
scripts/clone-cohort.sh infiniflow__ragflow

# More parallelism for the initial clone (good network)
PARALLEL=8 scripts/clone-cohort.sh
```

The script is idempotent — re-running it does a shallow `git fetch +
reset --hard` on existing clones, so it doubles as the "refresh" pass
before a re-audit run.

### Verifying surveys against clones

Each survey ends with one or more `*Audit YYYY-MM-DD: clone-verified
against ...*` footer paragraphs. To re-audit:

1. `scripts/clone-cohort.sh` (refresh local clones)
2. Open `surveys/<slug>.md` and `surveys/_clones/<slug>/` side by side
3. Spot-check the survey's specific claims (file paths, version pins,
   integration counts, license, link targets)
4. Append a new footer line:

   ```
   *Re-audit YYYY-MM-DD: <delta vs. previous audit>. Corrections: ...
   Verified: ...*
   ```

Existing audit footers are the template — see `surveys/getzep__graphiti.md`
or `surveys/run-llama__llama_index.md` for canonical examples.

### Continuous re-verification

For automated re-audits, the project ships with the `curating-agentic-kbs`
skill (run via `/loop`) which alternates between discovering candidate
repos and re-auditing existing surveys. The clone-cohort.sh script
provides the local working copy that loop reads from.
