#!/usr/bin/env bash

set -euo pipefail

current_script_path=$(realpath "${BASH_SOURCE[0]}")
plugin_dir=$(realpath "$(dirname "$(dirname "$current_script_path")")")

# shellcheck source=utils.bash
. "${plugin_dir}/lib/utils.bash"

# Downloads a PHP release package.
#
# Arguments:
#   The version of PHP to download.
#   The filename to use when saving the release package locally.
download_release() {
	local version="$1"
	local filename="$2"

	local url

	# If ASDF_INSTALL_TYPE isn't set, assume the installation type is "version."
	if [ "${ASDF_INSTALL_TYPE:-version}" = "ref" ]; then
		url="${gh_repo}/archive/${version}.tar.gz"
		asdf_info "Downloading ${tool_name} ref ${version}..."
	else
		url="${distributions_url}/php-${version}.tar.gz"
		asdf_info "Downloading ${tool_name} version ${version}..."
	fi

	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || asdf_fail "Could not download $url"
}
