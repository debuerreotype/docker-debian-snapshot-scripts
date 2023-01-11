#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

commit="$(bashbrew cat --format '{{ .Manifest.Global.ArchGitCommit arch }}' https://github.com/docker-library/official-images/raw/master/library/debian)"
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

	foundFile=
	for file in \
		'rootfs.debian-sources-snapshot=debian.sources' \
		'rootfs.sources-list-snapshot=sources.list' \
	; do
		remoteFile="${file%%=*}"
		localFile="${file#$remoteFile=}"
		if ! wget -qO "$target/$localFile" "https://github.com/debuerreotype/docker-debian-artifacts/raw/$commit/$suite/$remoteFile"; then
			rm -rf "$target/$localFile"
			continue
		fi
		foundFile="$localFile"
		break
	done
	if [ -z "$foundFile" ]; then
		echo "Skipping '$suite' (debian.sources / sources.list download failed)"
		continue
	fi

	if [ "$foundFile" = 'sources.list' ]; then
		targetDir='/etc/apt'
	else
		targetDir='/etc/apt/sources.list.d'
	fi

	cat > "$target/Dockerfile" <<-EODF
		FROM debian:$suite-$serial
		RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/docker-snapshot.conf
		RUN [ -s "$targetDir/$foundFile" ]
		COPY $foundFile $targetDir/
	EODF
done
