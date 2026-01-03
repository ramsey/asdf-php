#!/usr/bin/env bats
# shellcheck disable=SC2317

ASDF_PHP_LOG_FILE=
ASDF_PHP_VERBOSE=

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'
	load '../test_helper/bats-file/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	load '../../lib/utils.bash'
}

# executed after each test
teardown() {
	if [[ -n "${ASDF_PHP_LOG_FILE:-}" ]]; then
		unset -v ASDF_PHP_LOG_FILE
	fi

	if [[ -n "${ASDF_PHP_VERBOSE:-}" ]]; then
		unset -v ASDF_PHP_VERBOSE
	fi
}

@test "asdf_log() uses first argument to log a message" {
	log() {
		local input
		local log

		while IFS= read -r input; do
			log="${log:+${log}, }${input}"
		done

		[ "$1" = "yes" ] \
			&& [ "$log" = "A log message" ] \
			&& return 0

		fail "The log command received unexpected arguments: ${*}"
	}

	asdf_log "A log message"
}

@test "asdf_log() uses streamed data to log a message" {
	log() {
		local input
		local log2

		while IFS= read -r input; do
			log2="${log2:+${log2}, }${input}"
		done

		[ "$1" = "yes" ] \
			&& [ "$log2" = "Another log message,     More log messages, Still more" ] \
			&& return 0

		fail "The log command received unexpected arguments: ${*}"
	}

	asdf_log <<-EOF
		Another log message
		    More log messages
		Still more
	EOF
}

@test "asdf_log() can log an empty message" {
	log() {
		local input
		local log3=""

		while IFS= read -r input; do
			log3="${log3:+${log3}, }${input}"
		done

		[ "$1" = "yes" ] \
			&& [ "$log3" = "" ] \
			&& return 0

		fail "The log command received unexpected arguments: ${*}"
	}

	printf "" | asdf_log
}

@test "asdf_info() prints an info message" {
	run -0 asdf_info "this is an info message"
	assert_output "asdf-php: this is an info message"
}

@test "asdf_fail() fails and exits" {
	run -1 asdf_fail "testing calling the plugin failure function"
	assert_output "asdf-php: testing calling the plugin failure function"
}

@test "asdf_fail() fails and exits with a different exit code" {
	run -42 asdf_fail "testing asdf_fail with a different exit code" 42
	assert_output "asdf-php: testing asdf_fail with a different exit code"
}

@test "is_truthy() passes with TRUE" {
	is_truthy TRUE
}

@test "is_truthy() passes with true" {
	is_truthy true
}

@test "is_truthy() passes with 'YES'" {
	is_truthy YES
}

@test "is_truthy() passes with 'yes'" {
	is_truthy yes
}

@test "is_truthy() passes with 'Y'" {
	is_truthy Y
}

@test "is_truthy() passes with 'y'" {
	is_truthy y
}

@test "is_truthy() passes with 'ON'" {
	is_truthy ON
}

@test "is_truthy() passes with 'on'" {
	is_truthy on
}

@test "is_truthy() passes with 1" {
	is_truthy 1
}

@test "is_truthy() fails with 'foobar'" {
	run ! is_truthy foobar
}

@test "is_truthy() fails with false" {
	run ! is_truthy false
}

@test "is_truthy() fails with 0" {
	run ! is_truthy 0
}

@test "is_truthy() fails with 'yessir'" {
	run ! is_truthy yessir
}

@test "is_truthy() fails with empty string" {
	run ! is_truthy
}

@test "log() uses tee to log to a file and stdout" {
	local tmp_dir

	tmp_dir="$(temp_make)"
	ASDF_PHP_LOG_FILE="${tmp_dir}/asdf-log-test.log"
	truncate -s 0 "$ASDF_PHP_LOG_FILE"

	tee() {
		local input
		local message

		while IFS= read -r input; do
			message="${message:+${message}, }${input}"
		done

		[ "$1" = "-a" ] \
			&& [ "$2" = "$ASDF_PHP_LOG_FILE" ] \
			&& [ "$message" = "This is my log message, Hello, world!" ] \
			&& return 0

		fail "The tee command received unexpected arguments: ${*}"
	}

	cat() {
		fail "The cat command was not expected in this context"
	}

	log "yes" <<-EOF
		This is my log message
		Hello, world!
	EOF

	if [ -d "$tmp_dir" ]; then
		temp_del "$tmp_dir"
	fi
}

@test "log() uses the value of the ASDF_PHP_VERBOSE environment variable" {
	local tmp_dir
	ASDF_PHP_VERBOSE="yes"

	tmp_dir="$(temp_make)"
	ASDF_PHP_LOG_FILE="${tmp_dir}/asdf-log-test.log"
	truncate -s 0 "$ASDF_PHP_LOG_FILE"

	tee() {
		local input
		local message2

		while IFS= read -r input; do
			message2="${message2:+${message2}, }${input}"
		done

		[ "$1" = "-a" ] \
			&& [ "$2" = "$ASDF_PHP_LOG_FILE" ] \
			&& [ "$message2" = "This is my log message" ] \
			&& return 0

		fail "The tee command received unexpected arguments: ${*}"
	}

	cat() {
		fail "The cat command was not expected in this context"
	}

	# We're passing "no" here to test that ASDF_PHP_VERBOSE="yes" overrides this argument.
	log "no" <<-EOF
		This is my log message
	EOF

	if [ -d "$tmp_dir" ]; then
		temp_del "$tmp_dir"
	fi
}

@test "log() uses cat to log to a file and NOT stdout" {
	local tmp_dir
	local file_contents

	tmp_dir="$(temp_make)"
	ASDF_PHP_LOG_FILE="${tmp_dir}/asdf-log-test.log"
	truncate -s 0 "$ASDF_PHP_LOG_FILE"

	tee() {
		fail "The tee command was not expected in this context"
	}

	cat() {
		local input
		local msg

		while IFS= read -r input; do
			msg="${msg:+${msg}, }${input}"
		done

		[ "$msg" = "This is another log message, Goodbye!" ] \
			&& printf "%s\n" "$msg" \
			&& return 0

		fail "The cat command received unexpected arguments: ${*}"
	}

	log <<-EOF
		This is another log message
		Goodbye!
	EOF

	while IFS= read -r line; do file_contents="$line"; done <"$ASDF_PHP_LOG_FILE"
	[ "$file_contents" = "This is another log message, Goodbye!" ]
}

@test "log() always logs to stdout if ASDF_PHP_LOG_FILE is not set" {
	expected_output=$(
		cat <<-EOF
			This is another log message
			Goodbye!
		EOF
	)

	tee() {
		fail "The tee command was not expected in this context"
	}

	cat() {
		fail "The cat command was not expected in this context"
	}

	run -0 log <<-EOF
		This is another log message
		Goodbye!
	EOF

	assert_output "$expected_output"
}

@test "sort_versions() sorts version numbers" {
	versions_to_sort="$(cat "$DIR/../fixtures/list_versions-cli-macos-aarch64-unsorted.txt")"
	expected_output="$(cat "$DIR/../fixtures/list_versions-cli-macos-aarch64.txt")"
	sorted_versions="$(printf "%s" "$versions_to_sort" | sort_versions)"

	[ "$sorted_versions" = "$expected_output" ]
}

@test "get_os() returns macos for Darwin" {
	uname() {
		if [[ "${*}" = "-s" ]]; then
			printf "Darwin\n"
		fi
	}

	run -0 get_os
	assert_output "macos"
}

@test "get_os() returns linux for anything else" {
	uname() {
		if [[ "${*}" = "-s" ]]; then
			printf "SomeOS\n"
		fi
	}

	run -0 get_os
	assert_output "linux"
}

@test "get_arch() returns aarch64 for arm64" {
	uname() {
		if [[ "${*}" = "-m" ]]; then
			printf "arm64\n"
		fi
	}

	run -0 get_arch
	assert_output "aarch64"
}

@test "get_arch() returns aarch64 for aarch64" {
	uname() {
		if [[ "${*}" = "-m" ]]; then
			printf "aarch64\n"
		fi
	}

	run -0 get_arch
	assert_output "aarch64"
}

@test "get_arch() returns x86_64 for anything else" {
	# A mock for the uname command.
	uname() {
		if [[ "${*}" = "-m" ]]; then
			printf "unknown\n"
		fi
	}

	run -0 get_arch
	assert_output "x86_64"
}

@test "tmp_file() creates a file" {
	run -0 tmp_file
	assert_file_exists "$output"
}
