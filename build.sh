#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")/suites"

serial="$(< serial)"

for df in */Dockerfile; do
	dir="$(dirname "$df")"
	suite="$(basename "$dir")"

	docker build --pull -t "debian/snapshot:$suite-$serial" "$dir"
done
