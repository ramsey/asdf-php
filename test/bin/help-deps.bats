#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'
}

@test "help.deps" {
	help-deps() {
		load '../../bin/help.deps'
	}

	run -0 help-deps

	assert_line "coreutils"
}
