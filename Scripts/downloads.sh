#!/bin/sh
# DMG downloads per GitHub release, plus the total. Needs `gh` logged in.
# Usage: Scripts/downloads.sh   (or: make downloads)
set -e
REPO="${REPO:-s4tr2/baaa}"
gh api "repos/$REPO/releases?per_page=100" --jq '
  .[] | .tag_name as $t | .published_at[:10] as $d
      | .assets[] | [$t, $d, .name, (.download_count|tostring)] | @tsv' |
awk -F'\t' 'BEGIN { printf "%-9s %-11s %-12s %s\n", "release", "published", "asset", "downloads" }
            { printf "%-9s %-11s %-12s %s\n", $1, $2, $3, $4; total += $4 }
            END { printf "%-9s %-11s %-12s %s\n", "total", "", "", total }'
