#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	# shellcheck disable=SC2317
	help-overview() {
		load '../../bin/help.overview'
	}
}

# executed after each test
teardown() {
	unset -f help-overview
}

@test "help.overview" {
	run -0 help-overview
	assert_line '  asdf install php '
}

@test "help.overview with ASDF_INSTALL_VERSION" {
	export ASDF_INSTALL_VERSION='8.3.2'

	run -0 help-overview
	assert_line '  asdf install php 8.3.2'

	unset -v ASDF_INSTALL_VERSION
}
