#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'
}

@test "exec-env" {
	exec-env() {
		load '../../bin/exec-env'
	}

	export ASDF_INSTALL_PATH="/path/to/install"

	assert [ -z "${COMPOSER_HOME:-}" ]
	exec-env
	assert [ -n "${COMPOSER_HOME:-}" ]
	assert_equal "${COMPOSER_HOME:-}" "/path/to/install/.composer"
}
