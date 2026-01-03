#!/usr/bin/env bats

@test "exec-env sets environment vars" {
	exec-env() {
		load '../../bin/exec-env'
	}

	# shellcheck disable=SC2034
	ASDF_INSTALL_PATH="/path/to/install"

	[ -z "${COMPOSER_HOME:-}" ]
	[ -z "${PHPRC:-}" ]
	[ -z "${PHP_INI_SCAN_DIR:-}" ]

	exec-env

	[ -n "${COMPOSER_HOME:-}" ]
	[ -n "${PHPRC:-}" ]
	[ -n "${PHP_INI_SCAN_DIR:-}" ]

	[ "${COMPOSER_HOME}" = "/path/to/install/composer" ]
	[ "${PHPRC}" = "/path/to/install/etc/php/php.ini" ]
	[ "${PHP_INI_SCAN_DIR}" = "/path/to/install/etc/php/conf.d" ]

	unset -v ASDF_INSTALL_PATH
	unset -v COMPOSER_HOME
	unset -v PHPRC
	unset -v PHP_INI_SCAN_DIR
}

@test "exec-env does not set environment vars if they already exist" {
	exec-env() {
		load '../../bin/exec-env'
	}

	# shellcheck disable=SC2034
	ASDF_INSTALL_PATH="/path/to/install"

	COMPOSER_HOME="/path/to/composer"
	PHPRC="/path/to/php.ini"
	PHP_INI_SCAN_DIR="/path/to/php/conf.d"

	exec-env

	[ -n "${COMPOSER_HOME:-}" ]
	[ -n "${PHPRC:-}" ]
	[ -n "${PHP_INI_SCAN_DIR:-}" ]

	[ "${COMPOSER_HOME}" = "/path/to/composer" ]
	[ "${PHPRC}" = "/path/to/php.ini" ]
	[ "${PHP_INI_SCAN_DIR}" = "/path/to/php/conf.d" ]

	unset -v ASDF_INSTALL_PATH
	unset -v COMPOSER_HOME
	unset -v PHPRC
	unset -v PHP_INI_SCAN_DIR
}
