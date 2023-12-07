#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
	GIT_OUTPUT="$(cat "$DIR"/../fixtures/git_ls_remote_tags_refs.txt)"

	# A mock for the git command.
	# shellcheck disable=SC2317
	git() {
		if [ "$1" != 'ls-remote' ]; then
			fail "Expected Git subcommand ls-remote; received $1"
		fi

		if [ "$2" != '--tags' ]; then
			fail "Expected Git ls-remote option --tags"
		fi

		if [ "$3" != '--refs' ]; then
			fail "Expected Git ls-remote option --refs"
		fi

		echo "$GIT_OUTPUT"
	}

	load '../../lib/versions.bash'
}

@test "list_stable_versions()" {
	expected_output="$(cat "$DIR"/../fixtures/list_stable_versions.txt)"
	run list_stable_versions
	assert_output "$expected_output"
}

@test "list_stable_versions() with argument '8'" {
	expected_output="$(cat "$DIR"/../fixtures/list_stable_versions_8.txt)"
	run list_stable_versions "8"
	assert_output "$expected_output"
}

@test "list_stable_versions() with argument '8.1'" {
	expected_output="$(cat "$DIR"/../fixtures/list_stable_versions_8_1.txt)"
	run list_stable_versions "8.1"
	assert_output "$expected_output"
}

@test "list_stable_versions() with argument '8.1.11'" {
	run list_stable_versions "8.1.11"
	assert_output "8.1.11"
}

@test "list_stable_versions() with argument '3' fails" {
	run ! list_stable_versions "3"
}
