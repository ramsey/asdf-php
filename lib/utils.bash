#!/usr/bin/env bash

set -euo pipefail

export tool_name="PHP"
export distributions_url="https://www.php.net/distributions"
export gh_repo="https://github.com/php/php-src"

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

export curl_opts

# Appends a message to the log.
#
# If you do not provide an argument, you may pipe output to this command
# to stream it to the log.
#
# Arguments:
#   The message to write to the log.
#
# shellcheck disable=SC2120
asdf_log() {
	local log_message="${1:-}"

	if [ -n "$log_message" ]; then
		printf "%s\n" "$log_message" | log "yes"
		return
	fi

	while IFS= read -r input; do
		printf "%s\n" "$input"
	done | log "yes"
}

# Prints an info log message.
#
# Arguments:
#   The message to print.
asdf_info() {
	printf "asdf-%s: %s\n" "$(echo "$tool_name" | tr '[:upper:]' '[:lower:]')" "${1:-}" | asdf_log
}

# Prints a failure message and returns an error status.
#
# Arguments:
#   The message to print.
asdf_fail() {
	local exit_code="${2:-1}"
	asdf_info "${1:-}"
	exit "$exit_code"
}

# Returns true if $1 is "true", "on", "yes", "y", or "1".
#
# Arguments:
#   The value to check for truthiness.
is_truthy() (
	shopt -s nocasematch
	[[ "${1:-}" =~ ^(true|on|yes|y|1)$ ]]
)

# Piping data to this command logs it to a file and, optionally, to stdout
#
# This function relies on a global log_file value. If log_file is not set, this
# function will always print to stdout, regardless of the value passed as the
# first argument.
#
# If the ASDF_PHP_VERBOSE environment variable is set, then it will override any
# argument passed to this function.
#
# Arguments:
#   Whether to print to stdout, defaults to "no". This accepts values that evaluate to truthy with is_truthy(), e.g., "true", "on", "yes", "y", or "1").
#
# shellcheck disable=SC2120
log() {
	local to_stdout

	# The value of ASDF_PHP_VERBOSE always overrides the argument.
	if [ -n "${ASDF_PHP_VERBOSE:-}" ]; then
		to_stdout="${ASDF_PHP_VERBOSE}"
	else
		to_stdout="${1:-no}"
	fi

	# If no log file is defined, or it does not exist, always write to stdout.
	if [ -z "${log_file:-}" ] || [ ! -f "$log_file" ]; then
		while IFS= read -r input; do
			printf "%s\n" "$input"
		done

		return
	fi

	if is_truthy "$to_stdout"; then
		tee -a "$log_file"
	else
		cat >>"$log_file"
	fi
}

# Sorts and returns a list of software version numbers.
#
# Arguments:
#   A list of version numbers to sort.
sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' \
		| LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n \
		| awk '{print $2}'
}
