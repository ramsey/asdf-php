#!/usr/bin/env bash

set -euo pipefail

current_script_path=$(realpath "${BASH_SOURCE[0]}")
plugin_dir=$(realpath "$(dirname "$(dirname "$current_script_path")")")

# shellcheck source=utils.bash
. "${plugin_dir}/lib/utils.bash"

# Returns a list of stable version numbers from the PHP GitHub repository.
list_stable_versions() {
	local semver
	IFS="." read -r -a semver <<<"${1:-}"

	local major="${semver[0]:-[[:digit:]]+}"
	local minor="${semver[1]:-[[:digit:]]+}"
	local patch="${semver[2]:-[[:digit:]]+}"

	git ls-remote --tags --refs "$gh_repo" \
		| grep -o -E "refs/tags/php-${major}\.${minor}\.${patch}\$" \
		| sed 's/refs\/tags\/php-//' \
		| cut -d/ -f3- \
		| sort_versions
}
