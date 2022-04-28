#!/bin/sh

# get the directory where I live
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd);

COMMIT_DATE=$(git log --no-walk --date=raw --format=%cd | sed 's/ .*//')
VERSION=$(date --date=@${COMMIT_DATE} +%Y.%m.%d+%H%M%S);
printf "%s" "${VERSION}";
