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
	assert_line '  asdf install php <version>'
	assert_line '  asdf install php latest:<version>'
}

@test "help.overview with ASDF_INSTALL_VERSION" {
	ASDF_INSTALL_VERSION='8.4.16'

	run -0 help-overview
	assert_line '  asdf install php 8.4.16'
	assert_line '  asdf install php latest:8.4'

	unset -v ASDF_INSTALL_VERSION
}

@test "help.overview with ASDF_INSTALL_VERSION and complex version string" {
	ASDF_INSTALL_VERSION='8.5.1-alpha1+ext-memcached'

	run -0 help-overview
	assert_line '  asdf install php 8.5.1-alpha1+ext-memcached'
	assert_line '  asdf install php latest:8.5'

	unset -v ASDF_INSTALL_VERSION
}
