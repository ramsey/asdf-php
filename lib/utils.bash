#!/usr/bin/env bash

set -euo pipefail

STATIC_PHP_BULK_PREFIX="https://dl.static-php.dev/static-php-cli/bulk"

# shellcheck disable=SC2034
STATIC_PHP_BULK_LIST="${STATIC_PHP_BULK_PREFIX}/?format=json"

# shellcheck disable=SC2034
GIT_PHP_TAG_RAW_PREFIX="https://github.com/php/php-src/raw/refs/tags/php-"

# shellcheck disable=SC2034
CURL_OPTS=(-fsSL)

# Appends a message to the log.
#
# If you do not provide an argument, you may pipe output to this command
# to stream it to the log.
#
# Arguments:
#   message - The message to write to the log.
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
#   message - The message to print.
asdf_info() {
	printf "asdf-php: %s\n" "${1:-}" | asdf_log
}

# Prints a failure message and exits with an error status.
#
# Arguments:
#   message - The message to print.
#   exit_code - An optional exit code to return; defaults to 1.
asdf_fail() {
	local exit_code="${2:-1}"
	asdf_info "${1:-}"
	exit "$exit_code"
}

# Prints a standardized name for the current operating system (i.e., "linux" or "macos").
#
# Set ASDF_PHP_OS to override the value reported by uname -s.
get_os() {
	if [[ -n "${ASDF_PHP_OS:-}" ]]; then
		printf "%s" "$ASDF_PHP_OS"
		return
	fi

	local uname_s
	uname_s=$(uname -s)

	if [[ "$uname_s" = "Darwin" ]]; then
		printf "macos"
	else
		printf "linux"
	fi
}

# Prints a standardized name for the current system architecture (i.e., "x86_64" or "aarch64").
#
# Set ASDF_PHP_ARCH to override the value reported by uname -m.
get_arch() {
	if [[ -n "${ASDF_PHP_ARCH:-}" ]]; then
		printf "%s" "$ASDF_PHP_ARCH"
		return
	fi

	local uname_m
	uname_m=$(uname -m)

	if [[ "$uname_m" = "arm64" || "$uname_m" = "aarch64" ]]; then
		printf "aarch64"
	else
		printf "x86_64"
	fi
}

# Returns true if the value is "true", "on", "yes", "y", or "1".
#
# Arguments:
#   value - The value to check for truthiness.
is_truthy() (
	shopt -s nocasematch
	[[ "${1:-}" =~ ^(true|on|yes|y|1)$ ]]
)

# Piping data to this command logs it to a file and, optionally, to stdout
#
# This function relies on the ASDF_PHP_LOG_FILE environment variable. If
# ASDF_PHP_LOG_FILE is not set, this function will always print to stdout,
# regardless of the value passed as the first argument.
#
# If the ASDF_PHP_VERBOSE environment variable is set, then it will override any
# argument passed to this function.
#
# Arguments:
#   to_stdout - Whether to print to stdout, defaults to "no". This accepts values that evaluate to truthy with is_truthy(), e.g., "true", "on", "yes", "y", or "1").
#
# shellcheck disable=SC2120
log() {
	local to_stdout

	# The value of ASDF_PHP_VERBOSE always overrides the argument.
	if [[ -n "${ASDF_PHP_VERBOSE:-}" ]]; then
		to_stdout="${ASDF_PHP_VERBOSE}"
	else
		to_stdout="${1:-no}"
	fi

	# If no log file is defined, or it does not exist, always write to stdout.
	if [[ -z "${ASDF_PHP_LOG_FILE:-}" || ! -f "$ASDF_PHP_LOG_FILE" ]]; then
		while IFS= read -r input; do
			printf "%s\n" "$input"
		done

		return
	fi

	if is_truthy "$to_stdout"; then
		tee -a "$ASDF_PHP_LOG_FILE"
	else
		cat >>"$ASDF_PHP_LOG_FILE"
	fi
}

# Creates a temporary file in a POSIX-compatible way, for systems that don't have mktemp.
tmp_file() (
	set -o noclobber

	set +o pipefail
	random_str=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom 2>/dev/null | head -c 10 || true)
	tmp_name="${TMPDIR:-/tmp}/tmp.${random_str}"
	set -o pipefail

	umask 0177
	printf "" >"$tmp_name" 2>/dev/null
	printf "%s\n" "$tmp_name"
)
