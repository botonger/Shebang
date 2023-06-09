#!/usr/bin/env bash
set -uo pipefail

isMerged=$(git show --name-only | grep Merge:)

if [ -z "$isMerged" ]; then
    git log -1 --name-only --pretty=format:'' | grep -v '^$'
else
    commitNumber=$(echo "$isMerged" | awk '{print $0}' | grep -o ' ' | wc -l)
    git log "-$(($commitNumber+1))" --name-only --pretty=format:'' | grep -v '^$'
fi
