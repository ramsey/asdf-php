#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'
}

@test "help.overview" {
	help-overview() {
		load '../../bin/help.overview'
	}

	run -0 help-overview

	assert_line "Basic usage:"
}
