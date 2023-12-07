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
		echo "$GIT_OUTPUT"
	}
}

@test "list-all" {
	list_all() {
		# shellcheck source=../../bin/list-all
		source "$DIR/../../bin/list-all" ''
	}

	expected_output="$(cat "$DIR"/../fixtures/list-all.txt)"
	run list_all
	assert_output "$expected_output"
}
