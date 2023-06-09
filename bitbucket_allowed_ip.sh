#!/usr/bin/env bash
set -euo pipefail

IS_INSTALLED=$(echo $(jq --version |sed -n '/jq-[[:digit:]]/p'))

#assume that brew has already installed
if [ -z "$IS_INSTALLED" ]; then
        brew install jq
fi

WHITE_LIST=$(curl -ks https://ip-ranges.atlassian.com | jq '.[]| select(type=="array")' \
                | jq -r '.[] | select(.mask_len <=32) | .cidr' \
                | tr '\n', ', ')

echo $WHITE_LIST | sed 's/,$//'
