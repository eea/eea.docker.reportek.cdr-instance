#!/bin/bash
# Next release version: <Zope minor>-<N>, ex: 5.14-3
# The Zope minor follows the eeacms/reportek-base-dr tag this image is built from (5.14-2 -> 5.14),
# N is the next free number for it in this repository.
set -e

zope=$(sed -nE 's#^FROM .*eeacms/reportek-base-dr:([0-9]+\.[0-9]+)-[0-9]+.*#\1#p' Dockerfile | head -n 1)
if [ -z "$zope" ]; then
    echo "The base image tag in the Dockerfile is not in the <zope>-<N> form" >&2
    exit 1
fi

last=$(git tag | awk -F- -v z="$zope" '($1 "") == (z "") && $2 ~ /^[0-9]+$/ {print $2}' | sort -n | tail -n 1)
echo "${zope}-$(( ${last:-0} + 1 ))"
