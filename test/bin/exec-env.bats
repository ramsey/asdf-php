#!/usr/bin/env bats

@test "exec-env" {
	exec-env() {
		load '../../bin/exec-env'
	}

	export ASDF_INSTALL_PATH="/path/to/install"
	export COMPOSER_HOME=""

	[ -z "${COMPOSER_HOME:-}" ]
	exec-env
	[ -n "${COMPOSER_HOME:-}" ]
	[  "${COMPOSER_HOME}" = "/path/to/install/.composer" ]
}
