#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	load '../../lib/versions.bash'

	static_php_json="$(cat "$DIR"/../fixtures/static-php-cli-bulk.json)"

	curl() {
		# shellcheck disable=SC2154
		if [[ "$1" != "${CURL_OPTS[*]}" ]]; then
			printf "Expected %s, but got %s\n" "${CURL_OPTS[*]}" "$1"
			return 1
		fi

		if [[ "$2" != "-o" ]]; then
			printf "Expected -o, but got %s\n" "$2"
			return 1
		fi

		if [[ ! -f "$3" ]]; then
			printf "Expected a file to exist at %s\n" "$3"
			return 1
		fi

		# shellcheck disable=SC2154
		if [[ "$4" != "$STATIC_PHP_BULK_LIST" ]]; then
			printf "Expected %s, but got %s\n" "$STATIC_PHP_BULK_LIST" "$4"
			return 1
		fi

		printf "%s\n" "$static_php_json" >"$3"
	}
}

@test "latest_stable_version()" {
	run -0 latest_stable_version "cli" "macos" "aarch64"
	assert_output "8.4.16"
}

@test "latest_stable_version() with version argument '8.1'" {
	run -0 latest_stable_version "cli" "macos" "aarch64" "8.1"
	assert_output "8.1.34"
}

@test "list_versions() for cli, macos, aarch64" {
	expected_output="$(cat "$DIR"/../fixtures/list_versions-cli-macos-aarch64.txt)"
	run -0 list_versions "cli" "macos" "aarch64"
	assert_output "$expected_output"
}

@test "list_versions() for fpm, macos, aarch64" {
	expected_output="$(cat "$DIR"/../fixtures/list_versions-fpm-macos-aarch64.txt)"
	run -0 list_versions "fpm" "macos" "aarch64"
	assert_output "$expected_output"
}

@test "list_versions() for cli, linux, x86_64" {
	expected_output="$(cat "$DIR"/../fixtures/list_versions-cli-linux-x86_64.txt)"
	run -0 list_versions "cli" "linux" "x86_64"
	assert_output "$expected_output"
}

@test "list_versions() with version argument '8'" {
	expected_output="$(cat "$DIR"/../fixtures/list_versions-cli-macos-aarch64-php-8.txt)"
	run -0 list_versions "cli" "macos" "aarch64" "8"
	assert_output "$expected_output"
}

@test "list_versions() with version argument '8.1'" {
	expected_output="$(cat "$DIR"/../fixtures/list_versions-cli-macos-aarch64-php-81.txt)"
	run -0 list_versions "cli" "macos" "aarch64" "8.1"
	assert_output "$expected_output"
}

@test "list_versions() with version argument '8.1.34'" {
	expected_output="$(cat "$DIR"/../fixtures/list_versions-cli-macos-aarch64-php-8134.txt)"
	run -0 list_versions "cli" "macos" "aarch64" "8.1.34"
	assert_output "$expected_output"
}

@test "list_versions() with version argument '3' fails" {
	run ! list_versions "cli" "macos" "aarch64" "3"
}
