#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'
	load '../test_helper/bats-file/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# shellcheck disable=SC2034
	ASDF_DOWNLOAD_PATH="$(temp_make)"

	# shellcheck disable=SC2034
	ASDF_INSTALL_PATH="$(temp_make)"

	# shellcheck disable=SC2034
	ASDF_INSTALL_VERSION="8.4.16"

	# shellcheck disable=SC2034
	ASDF_PHP_OS="linux"

	# shellcheck disable=SC2034
	ASDF_PHP_ARCH="x86_64"

	cp "$DIR/../fixtures/php" "$ASDF_DOWNLOAD_PATH/php"
	cp "$DIR/../fixtures/php.ini-development" "$ASDF_DOWNLOAD_PATH/php.ini-development"
	cp "$DIR/../fixtures/php.ini-production" "$ASDF_DOWNLOAD_PATH/php.ini-production"
	cp "$DIR/../fixtures/composer.phar" "$ASDF_DOWNLOAD_PATH/composer.phar"
}

teardown() {
	unset -v ASDF_DOWNLOAD_PATH
	unset -v ASDF_INSTALL_PATH
	unset -v ASDF_INSTALL_VERSION
	unset -v ASDF_PHP_OS
	unset -v ASDF_PHP_ARCH
}

@test "install command installs the files" {
	install() {
		# shellcheck source=../../bin/install
		source "$DIR/../../bin/install"
	}

	expected_output=$(
		cat <<-EOF
			asdf-php: Installing PHP to $ASDF_INSTALL_PATH
			asdf-php: Installing PHP INI files to $ASDF_INSTALL_PATH
			asdf-php: Installing Composer to $ASDF_INSTALL_PATH

			PHP 8.x.x (cli) (built: Feb 28 2025 10:16:09) (NTS)
			Copyright (c) The PHP Group
			Zend Engine v4.x.x, Copyright (c) Zend Technologies

			Loaded Configuration File:         /path/to/install/etc/php/php.ini
			Scan for additional .ini files in: /path/to/install/etc/php/conf.d
			Additional .ini files parsed:      (none)

			Composer version 2.x.x 2025-02-25 13:03:50

			asdf-php: PHP 8.4.16 installation was successful!
		EOF
	)

	run -0 install
	assert_output "$expected_output"
	assert_file_exists "${ASDF_INSTALL_PATH}/bin/php"
	assert_file_not_exists "${ASDF_INSTALL_PATH}/bin/php-fpm"
	assert_file_exists "${ASDF_INSTALL_PATH}/bin/composer"
	assert_file_exists "${ASDF_INSTALL_PATH}/etc/php/php.ini"
	assert_dir_exists "${ASDF_INSTALL_PATH}/etc/php/conf.d"
	assert_dir_exists "${ASDF_INSTALL_PATH}/composer"
}
