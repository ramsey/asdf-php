#!/usr/bin/env bats

download_dir=
install_dir=

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'
	load '../test_helper/bats-file/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	load '../../lib/install.bash'

	download_dir="$(temp_make)"
	install_dir="$(temp_make)"

	cp "$DIR/../fixtures/php" "$download_dir/php"
	cp "$DIR/../fixtures/php.ini-development" "$download_dir/php.ini-development"
	cp "$DIR/../fixtures/php.ini-production" "$download_dir/php.ini-production"
	cp "$DIR/../fixtures/composer.phar" "$download_dir/composer.phar"
}

@test "install_version() returns success status" {
	expected_output=$(
		cat <<-EOF
			asdf-php: Installing PHP to $install_dir
			asdf-php: Installing PHP INI files to $install_dir
			asdf-php: Installing Composer to $install_dir

			PHP 8.x.x (cli) (built: Feb 28 2025 10:16:09) (NTS)
			Copyright (c) The PHP Group
			Zend Engine v4.x.x, Copyright (c) Zend Technologies

			Loaded Configuration File:         /path/to/install/etc/php/php.ini
			Scan for additional .ini files in: /path/to/install/etc/php/conf.d
			Additional .ini files parsed:      (none)

			Composer version 2.x.x 2025-02-25 13:03:50

			asdf-php: PHP 8.5.1 installation was successful!
		EOF
	)

	run -0 install_version "8.5.1" "$download_dir" "$install_dir"
	assert_output "$expected_output"
	assert_file_exists "${install_dir}/bin/php"
	assert_file_not_exists "${install_dir}/bin/php-fpm"
	assert_file_exists "${install_dir}/bin/composer"
	assert_file_exists "${install_dir}/etc/php/php.ini"
	assert_dir_exists "${install_dir}/etc/php/conf.d"
	assert_dir_exists "${install_dir}/composer"
}

@test "install_version() returns success status when php-fpm is downloaded" {
	cp "$DIR/../fixtures/php-fpm" "$download_dir/php-fpm"

	expected_output=$(
		cat <<-EOF
			asdf-php: Installing PHP to $install_dir
			asdf-php: Installing PHP INI files to $install_dir
			asdf-php: Installing Composer to $install_dir

			PHP 8.x.x (cli) (built: Feb 28 2025 10:16:09) (NTS)
			Copyright (c) The PHP Group
			Zend Engine v4.x.x, Copyright (c) Zend Technologies

			PHP 8.x.x (fpm-fcgi) (built: Feb 28 2025 10:16:09) (NTS)
			Copyright (c) The PHP Group
			Zend Engine v4.x.x, Copyright (c) Zend Technologies

			Loaded Configuration File:         /path/to/install/etc/php/php.ini
			Scan for additional .ini files in: /path/to/install/etc/php/conf.d
			Additional .ini files parsed:      (none)

			Composer version 2.x.x 2025-02-25 13:03:50

			asdf-php: PHP 8.5.1 installation was successful!
		EOF
	)

	run -0 install_version "8.5.1" "$download_dir" "$install_dir"
	assert_output "$expected_output"
	assert_file_exists "${install_dir}/bin/php"
	assert_file_exists "${install_dir}/bin/php-fpm"
	assert_file_exists "${install_dir}/bin/composer"
	assert_file_exists "${install_dir}/etc/php/php.ini"
	assert_dir_exists "${install_dir}/etc/php/conf.d"
	assert_dir_exists "${install_dir}/composer"
}

@test "install_version() returns failure status" {
	# Override php_composer_install to have it return a failed status.
	php_composer_install() {
		return 1
	}

	expected_output=$(
		cat <<-EOF
			asdf-php: Installing PHP to $install_dir
			asdf-php: Installing PHP INI files to $install_dir
			asdf-php: An error occurred while installing PHP 8.5.1.
		EOF
	)

	# The install dir should already exist, since we created it in the test setup.
	assert_dir_exists "$install_dir"

	run -7 install_version "8.5.1" "$download_dir" "$install_dir"
	assert_output "$expected_output"

	# We should have deleted the install dir when we failed.
	assert_dir_not_exists "$install_dir"
}
