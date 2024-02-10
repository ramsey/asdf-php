#!/usr/bin/env bats
# shellcheck disable=SC2317

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
	assert_line '  asdf install php '
}

@test "help.overview with ASDF_INSTALL_VERSION" {
	help-overview() {
		load '../../bin/help.overview'
	}

	export ASDF_INSTALL_VERSION='8.3.2'

	run -0 help-overview
	assert_line '  asdf install php 8.3.2'
}

