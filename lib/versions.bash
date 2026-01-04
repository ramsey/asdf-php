#!/usr/bin/env bash

set -euo pipefail

current_script_path=$(realpath "${BASH_SOURCE[0]}")
plugin_dir=$(realpath "$(dirname "$(dirname "$current_script_path")")")

# shellcheck source=utils.bash
. "${plugin_dir}/lib/utils.bash"

# Returns the latest stable version, optionally for the given query value (i.e., "8.4").
#
# Arguments:
#   sapi - The PHP SAPI to get the version for.
#   os - The operating system to get the version for.
#   arch - The system architecture to get the version for.
#   query - A version string to query for, e.g., "8.4" returns the latest version in the "8.4" series.
latest_stable_version() {
	local sapi="$1"
	local os="$2"
	local arch="$3"
	local query="${4:-}"

	printf "%s" "$(list_versions "$sapi" "$os" "$arch" "$query" | tail -n1 | xargs printf "%s")"
}

# Returns a list of version numbers from the Static PHP download repository.
#
# Arguments:
#   sapi - The PHP SAPI to list versions for.
#   os - The operating system to list versions for.
#   arch - The system architecture to list versions for.
#   query - A version string to query for, e.g., "8.4" returns all versions starting with "8.4."
list_versions() {
	local sapi="$1"
	local os="$2"
	local arch="$3"
	local query="${4:-}"

	local major="[0-9]+"
	local minor="[0-9]+"
	local patch="[0-9]+"

	local semver
	semver="$(parse_semver "$query")"

	if [[ -n "$semver" ]]; then
		IFS="|" read -r -a semver <<<"${semver}"
		major="${semver[0]:-$major}"
		minor="${semver[1]:-$minor}"
		patch="${semver[2]:-$patch}"
	fi

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

# Attempts to find and return a compatible version string for the given version input.
#
# Arguments:
#   sapi - The PHP SAPI to get the normalized version for.
#   os - The operating system to get the normalized version for.
#   arch - The system architecture to get the normalized version for.
#   version - The version string to normalize.
normalize_version() {
	local sapi="$1"
	local os="$2"
	local arch="$3"
	local version_input="$4"

	local version=""

	if [[ "$version_input" = "latest" ]]; then
		version="$(latest_stable_version "$sapi" "$os" "$arch")"
	elif [[ "$version_input" =~ ^latest: ]]; then
		version="$(latest_stable_version "$sapi" "$os" "$arch" "${version_input:7}")"
	else
		# If it's a valid version number, pass it to latest_stable_version(),
		# in case it's a partial version number.
		if [[ -n "$(parse_semver "$version_input")" ]]; then
			version="$(latest_stable_version "$sapi" "$os" "$arch" "$version_input")"
		fi
	fi

	if [[ -z "$version" ]]; then
		return 1
	fi

	printf "%s" "$version"
}

# Parse the major, minor and patch versions of a semver string.
#
# The returned value is a pipe-delimited string, which may be parsed into an array with:
#
#   IFS="|" read -r -a semver <<<"$(parse_semver "8.4.16+build.info")"
#   echo "${semver[0]}" # Prints "8"
#   echo "${semver[1]}" # Prints "4"
#   echo "${semver[2]}" # Prints "16"
#   echo "${semver[3]}" # Pre-release identifier; prints "" (empty string because it's not present in the input)
#   echo "${semver[4]}" # Metadata information; prints "build.info"
#
# In proper semver <https://semver.org>, there must be a hyphen to delimit the pre-release version. However, PHP does
# not include the hyphen in its pre-release version (e.g., "8.5.0alpha1", "8.5.0RC1", etc.), so we must accommodate.
# We also want to allow the use of the +-symbol in the metadata string, so we can support strings like:
#
#   8.6.0RC3+xdebug+memcached+redis
#
# Arguments:
#   token - The semver string to parse.
parse_semver() {
	local token="$1"
	local major=0
	local minor=0
	local patch=0
	local prerelease=0
	local metadata=0

	local regex="^([0-9]+)(\.[0-9]+)?(\.[0-9]+)?(-?[0-9A-Za-z\.\-]+)?(\+[0-9A-Za-z\+\.\-]+)?$"

	if [[ $token =~ $regex ]]; then
		major="${BASH_REMATCH[1]:-}"

		minor="${BASH_REMATCH[2]:-}"
		minor="${minor#.}"

		patch="${BASH_REMATCH[3]:-}"
		patch="${patch#.}"

		prerelease="${BASH_REMATCH[4]:-}"
		prerelease="${prerelease#-}"

		metadata="${BASH_REMATCH[5]:-}"
		metadata="${metadata#+}"
	else
		return 1
	fi

	printf "%s|%s|%s|%s|%s|" "$major" "$minor" "$patch" "$prerelease" "$metadata"
}

# Returns a PHP-style version string without any build metadata attached.
#
# For example, if the version string is "8.4.16RC1+memcached-xdebug", this returns "8.4.16RC1".
#
# Note: "PHP-style" is a reference to not using a hyphen between the version number and the pre-release version, as is
# defined by the semver specification <https://semver.org>.
php_version_without_metadata() {
	local version="$1"

	local major="0"
	local minor="0"
	local patch="0"
	local prerelease=""

	local semver
	semver="$(parse_semver "$version")"
	if [[ -n "$semver" ]]; then
		IFS="|" read -r -a semver <<<"$semver"
		major="${semver[0]:-$major}"
		minor="${semver[1]:-$minor}"
		patch="${semver[2]:-$patch}"
		prerelease="${semver[3]:-$prerelease}"
	fi

	printf "%s.%s.%s%s" "$major" "$minor" "$patch" "$prerelease"
}

# Sorts and returns a list of software version numbers.
#
# Arguments:
#   versions - A list of version numbers to sort.
sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' \
		| LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n \
		| awk '{print $2}'
}
