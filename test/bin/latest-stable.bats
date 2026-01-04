#!/usr/bin/env bats
# shellcheck disable=SC2329

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
		[[ -f "$3" ]] || "Expected a file to exist at $3"
		printf "%s\n" "$static_php_json" >"$3"
	}

	latest_stable() {
		# shellcheck source=../../bin/latest-stable
		source "$DIR/../../bin/latest-stable" "${1:-}"
	}
}

teardown() {
	unset -f curl
	unset -f latest_stable
	unset -v ASDF_PHP_OS
	unset -v ASDF_PHP_ARCH
}

@test "latest-stable" {
	run -0 latest_stable
	assert_output "8.4.16"
}

@test "latest-stable with query" {
	run -0 latest_stable "8.1"
	assert_output "8.1.34"
}
