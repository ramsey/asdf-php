#!/usr/bin/env bash

set -euo pipefail

current_script_path=$(realpath "${BASH_SOURCE[0]}")
plugin_dir=$(realpath "$(dirname "$(dirname "$current_script_path")")")

# shellcheck source=utils.bash
. "${plugin_dir}/lib/utils.bash"

# Returns a list of version numbers from the Static PHP download repository.
#
# Arguments:
#   sapi - The PHP SAPI to list versions for.
#   os - The operating system to list versions for.
#   arch - The system architecture to list versions for.
list_versions() {
	local sapi="$1"
	local os="$2"
	local arch="$3"

	local semver
	IFS="." read -r -a semver <<<"${4:-}"

	local major="${semver[0]:-[[:digit:]]+}"
	local minor="${semver[1]:-[[:digit:]]+}"
	local patch="${semver[2]:-[[:digit:]]+}"

	local tmp_name
	tmp_name=$(tmp_file)

	curl ${CURL_OPTS[@]+"${CURL_OPTS[@]}"} -o "$tmp_name" "$STATIC_PHP_BULK_LIST" \
		|| asdf_fail "Could not download $STATIC_PHP_BULK_LIST"

	awk <"$tmp_name" -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/name\042/){ val=$(i+1); gsub(/"/, "", val); print val }}}' \
		| grep -o -E "php\-${major}\.${minor}\.${patch}\-${sapi}\-${os}\-${arch}\.tar\.gz" \
		| sed 's/php-//' \
		| sed "s/-${sapi}-${os}-${arch}.tar.gz//" \
		| sort_versions
}
