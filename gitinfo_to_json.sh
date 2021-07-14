#!/bin/bash

OUTPUT_FILE="gitinfo.json"

GIT_SHORT_HASH=`git rev-parse --short HEAD`
GIT_CUR_TAG="$(git describe --exact-match  2> /dev/null)"

JSON=$(printf '{"hash":"%s", "tag":"%s"}' $GIT_SHORT_HASH $GIT_CUR_TAG)
echo $JSON >> $OUTPUT_FILE


