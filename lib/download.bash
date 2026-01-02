#!/usr/bin/env bash

set -euo pipefail

current_script_path=$(realpath "${BASH_SOURCE[0]}")
plugin_dir=$(realpath "$(dirname "$(dirname "$current_script_path")")")

# shellcheck source=utils.bash
. "${plugin_dir}/lib/utils.bash"

# Downloads a PHP release for installation by asdf.
#
# If the environment variable ASDF_PHP_FPM is present and contains a truthy value, as supported by is_truthy, then
# php-fpm will also be downloaded.
#
# Arguments:
#   version - The version of PHP to download.
#   download_path - The path where PHP should be downloaded and unpacked.
#   os - The operating system on which we want to run PHP.
#   arch - The system architecture on which we want to run PHP.
download_release() {
	local version="$1"
	local download_path="$2"
	local os="$3"
	local arch="$4"

	download_static_php "$version" "$download_path" "cli" "$os" "$arch"

	if is_truthy "${ASDF_PHP_FPM:-no}"; then
		download_static_php "$version" "$download_path" "fpm" "$os" "$arch"
	fi

	download_php_ini "$version" "$download_path" "development"
	download_php_ini "$version" "$download_path" "production"
}

# Downloads a PHP release for installation by asdf.
#
# Arguments:
#   version - The version of PHP to download.
#   download_path - The path where PHP should be downloaded and unpacked.
#   sapi - The SAPI variant (i.e., "cli" or "fpm").
#   os - The target operating system (i.e., "macos" or "linux").
#   arch - The target architecture (i.e., "x86_64" or "aarch64").
download_static_php() {
	local version="$1"
	local download_path="$2"
	local sapi="$3"
	local os="$4"
	local arch="$5"

	local download_file
	download_file="${download_path}/php-${version}-${sapi}-${os}-${arch}.tar.gz"

	local url
	url="${static_php_bulk_prefix}/php-${version}-${sapi}-${os}-${arch}.tar.gz"

	asdf_info "Downloading ${tool_name} version ${version} (${sapi}, ${os}, ${arch})..."

	curl "${curl_opts[@]}" -o "$download_file" -C - "$url" || asdf_fail "Could not download $url"

	unpack_download "$download_file" "$download_path"
}

# Unpacks the downloaded binary and removes the download file.
#
# Arguments:
#   download_file - The path to the file that needs to be unpacked.
#   download_path - The path to the location where the contents of the download_file should be unpacked.
unpack_download() {
	local download_file="$1"
	local download_path="$2"

	#  Extract contents of tar.gz file into the download directory
	tar -xzf "$download_file" -C "$download_path" >/dev/null 2>&1 || asdf_fail "Could not extract $download_file"

	# Remove the tar.gz file since we don't need to keep it
	rm "$download_file"
}

# Downloads a php.ini file from the PHP project for the given PHP version.
#
# Arguments:
#   version - The version of PHP for which the INI file should be downloaded.
#   download_path - The path to the location where the INI file should be downloaded.
#   variant - Whether to download the "development" or "production" variant of the INI file.
download_php_ini() {
	local version="$1"
	local download_path="$2"
	local variant="$3"

	asdf_info "Downloading php.ini-${variant} file for PHP ${version}..."

	local download_file
	download_file="${download_path}/php.ini-${variant}"

	local url
	url="${git_php_tag_raw_prefix}${version}/php.ini-${variant}"

	curl "${curl_opts[@]}" -o "$download_file" -C - "$url" || asdf_fail "Could not download $url"
}
