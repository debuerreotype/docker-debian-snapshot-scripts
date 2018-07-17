#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

arch='amd64'

commit="$(git ls-remote https://github.com/debuerreotype/docker-debian-artifacts.git "refs/heads/dist-$arch" | cut -d$'\t' -f1)"
[ -n "$commit" ]

serial="$(wget -qO- "https://github.com/debuerreotype/docker-debian-artifacts/raw/$commit/serial")"

suites="$(wget -qO- "https://github.com/debuerreotype/docker-debian-artifacts/raw/$commit/suites")"
suites=( $suites )

rm -rf suites
mkdir suites

echo "$serial" > suites/serial

for suite in "${suites[@]}"; do
	echo
	echo "Updating '$suite' ..."

	target="suites/$suite"
	mkdir -p "$target"

	if ! wget -qO "$target/sources.list" "https://github.com/debuerreotype/docker-debian-artifacts/raw/$commit/$suite/rootfs.sources-list-snapshot"; then
		echo "Skipping '$suite' (sources.list download failed)"
		continue
	fi

	cat > "$target/Dockerfile" <<-EODF
		FROM debian:$suite-$serial
		RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/docker-snapshot.conf
		COPY sources.list /etc/apt/
	EODF
done
