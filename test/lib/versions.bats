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
	run -0 list_versions "cli" "macos" "aarch64" "8.1.34"
	assert_output "8.1.34"
}

@test "list_versions() with version argument '3' fails" {
	run ! list_versions "cli" "macos" "aarch64" "3"
}

@test "list_versions() with invalid version string" {
	expected_output="$(cat "$DIR"/../fixtures/list_versions-cli-linux-x86_64.txt)"
	run -0 list_versions "cli" "linux" "x86_64" "invalid.version.string"
	assert_output "$expected_output"
}

@test "parse_semver() succeeds with 1.2.3" {
	run -0 parse_semver "1.2.3"

	IFS="|" read -r -a semver <<<"$output"
	[ "${semver[0]}" = "1" ]
	[ "${semver[1]}" = "2" ]
	[ "${semver[2]}" = "3" ]
	[ "${semver[3]}" = "" ]
	[ "${semver[4]}" = "" ]
}

@test "parse_semver() succeeds with 1.2.4+foobar" {
	run -0 parse_semver "1.2.4+foobar"
	assert_output "1|2|4||foobar|"
}

@test "parse_semver() succeeds with 1.2.5-alpha01" {
	run -0 parse_semver "1.2.5-alpha01"
	assert_output "1|2|5|alpha01||"
}

@test "parse_semver() fails with not-a-semver" {
	run -1 parse_semver "not-a-semver"
}

@test "parse_semver() succeeds with 2.3.4abc and treats 'abc' as a pre-release version" {
	run -0 parse_semver "2.3.4abc"
	assert_output "2|3|4|abc||"
}

@test "parse_semver() fails with a1.2.3" {
	run -1 parse_semver "a1.2.3"
}

@test "parse_semver() succeeds with 1.0.0-alpha" {
	run -0 parse_semver "1.0.0-alpha"
	assert_output "1|0|0|alpha||"
}

@test "parse_semver() succeeds with 1.0.0-alpha.1" {
	run -0 parse_semver "1.0.0-alpha.1"
	assert_output "1|0|0|alpha.1||"
}

@test "parse_semver() succeeds with 1.0.0-0.3.7" {
	run -0 parse_semver "1.0.0-0.3.7"
	assert_output "1|0|0|0.3.7||"
}

@test "parse_semver() succeeds with 1.0.0-x.7.z.92" {
	run -0 parse_semver "1.0.0-x.7.z.92"
	assert_output "1|0|0|x.7.z.92||"
}

@test "parse_semver() succeeds with 1.0.0-x-y-z.--" {
	run -0 parse_semver "1.0.0-x-y-z.--"
	assert_output "1|0|0|x-y-z.--||"
}

@test "parse_semver() succeeds with 1.0.0-alpha+001" {
	run -0 parse_semver "1.0.0-alpha+001"
	assert_output "1|0|0|alpha|001|"
}

@test "parse_semver() succeeds with 1.0.0+20130313144700" {
	run -0 parse_semver "1.0.0+20130313144700"
	assert_output "1|0|0||20130313144700|"
}

@test "parse_semver() succeeds with 1.0.0-beta+exp.sha.5114f85" {
	run -0 parse_semver "1.0.0-beta+exp.sha.5114f85"
	assert_output "1|0|0|beta|exp.sha.5114f85|"
}

@test "parse_semver() succeeds with 1.0.0+21AF26D3----117B344092BD" {
	run -0 parse_semver "1.0.0+21AF26D3----117B344092BD"
	assert_output "1|0|0||21AF26D3----117B344092BD|"
}

@test "parse_semver() succeeds with 1" {
	run -0 parse_semver "1"
	assert_output "1|||||"
}

@test "parse_semver() succeeds with 1.2" {
	run -0 parse_semver "1.2"
	assert_output "1|2||||"
}

@test "parse_semver() succeeds with 1.2-pl1+info" {
	run -0 parse_semver "1.2-pl1+info"
	assert_output "1|2||pl1|info|"
}

@test "parse_semver() succeeds with 1-pl1+info" {
	run -0 parse_semver "1-pl1+info"
	assert_output "1|||pl1|info|"
}

@test "parse_semver() succeeds with 1-pl1" {
	run -0 parse_semver "1-pl1"
	assert_output "1|||pl1||"
}

@test "parse_semver() succeeds with 1+info" {
	run -0 parse_semver "1+info"
	assert_output "1||||info|"
}

@test "parse_semver() succeeds with 8.5.0alpha1" {
	run -0 parse_semver "8.5.0alpha1"
	assert_output "8|5|0|alpha1||"
}

@test "parse_semver() succeeds with 8.5.0alpha1-1+build1" {
	run -0 parse_semver "8.5.0alpha1-1+build1"
	assert_output "8|5|0|alpha1-1|build1|"
}

@test "parse_semver() succeeds with 8.5.1RC1+xdebug+memcached+redis" {
	run -0 parse_semver "8.5.1RC1+xdebug+memcached+redis"
	assert_output "8|5|1|RC1|xdebug+memcached+redis|"
}

@test "sort_versions() sorts version numbers" {
	versions_to_sort="$(cat "$DIR/../fixtures/list_versions-cli-macos-aarch64-unsorted.txt")"
	expected_output="$(cat "$DIR/../fixtures/list_versions-cli-macos-aarch64.txt")"
	sorted_versions="$(printf "%s" "$versions_to_sort" | sort_versions)"

	[ "$sorted_versions" = "$expected_output" ]
}

@test "normalize_version() fails for invalid.version.string" {
	run -1 normalize_version "cli" "macos" "aarch64" "invalid.version.string"
}

@test "normalize_version() returns latest stable version" {
	run -0 normalize_version "cli" "macos" "aarch64" "latest"
	assert_output "8.4.16"
}

@test "normalize_version() returns latest 8.1 version" {
	run -0 normalize_version "cli" "macos" "aarch64" "latest:8.1"
	assert_output "8.1.34"
}

@test "normalize_version() validates version string and returns it" {
	run -0 normalize_version "cli" "macos" "aarch64" "8.1.34"
	assert_output "8.1.34"
}

@test "normalize_version() treats partial version string as request for latest" {
	run -0 normalize_version "cli" "macos" "aarch64" "8.0"
	assert_output "8.0.30"
}

@test "normalize_version() fails for non-existent version" {
	run -1 normalize_version "cli" "macos" "aarch64" "8.0.31"
}
