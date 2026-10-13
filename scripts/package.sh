#!/bin/sh
# Builds the book and writes a static site archive.
#
# The archive contains the contents of book/ at its root, so it can be
# extracted into a static host's document root.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

mdbook build
rm -f port0-docs.tar.gz
tar -czf port0-docs.tar.gz -C book .
printf 'wrote %s\n' "$root/port0-docs.tar.gz"
