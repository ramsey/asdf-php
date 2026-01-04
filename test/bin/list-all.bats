#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# shellcheck disable=SC2034
	ASDF_PHP_OS="linux"

	# shellcheck disable=SC2034
	ASDF_PHP_ARCH="x86_64"

	static_php_json="$(cat "$DIR"/../fixtures/static-php-cli-bulk.json)"

	curl() {
		if [[ ! -f "$3" ]]; then
			printf "Expected a file to exist at %s" "$3"
			return 1
		fi

		printf "%s\n" "$static_php_json" >"$3"
	}

	list_all() {
		# shellcheck source=../../bin/list-all
		source "$DIR/../../bin/list-all" "${1:-}"
	}
}

teardown() {
	unset -f curl
	unset -f list_all
	unset -v ASDF_PHP_OS
	unset -v ASDF_PHP_ARCH
}

@test "list-all" {
	# Add a single space character to the end of the expected output.
	expected_output="$(cat "$DIR"/../fixtures/list-all-cli-linux-x86_64.txt) "
	run -0 list_all
	assert_output "$expected_output"
}

@test "list-all with query" {
	# Add a single space character to the end of the expected output.
	expected_output="$(cat "$DIR"/../fixtures/list-all-cli-linux-x86_64-php-81.txt) "
	run -0 list_all "8.1"
	assert_output "$expected_output"
}
