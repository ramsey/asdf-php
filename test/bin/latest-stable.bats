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

@test "latest-stable" {
	latest_stable() {
		# shellcheck source=../../bin/latest-stable
		source "$DIR/../../bin/latest-stable" ''
	}

	run latest_stable
	assert_output "8.3.1"
}
