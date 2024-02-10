#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'
}

@test "list-bin-paths" {
	list-bin-paths() {
		load '../../bin/list-bin-paths'
	}

	run -0 list-bin-paths
	assert_output "bin sbin .composer/vendor/bin"
}
