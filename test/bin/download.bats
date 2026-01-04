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
	ASDF_INSTALL_VERSION="latest:8.1"

	# shellcheck disable=SC2034
	ASDF_PHP_OS="linux"

	# shellcheck disable=SC2034
	ASDF_PHP_ARCH="x86_64"
}

teardown() {
	unset -v ASDF_DOWNLOAD_PATH
	unset -v ASDF_INSTALL_VERSION
	unset -v ASDF_PHP_OS
	unset -v ASDF_PHP_ARCH
}

# bats test_tags=integration
@test "download command downloads and extracts file" {
	download() {
		# shellcheck source=../../bin/download
		source "$DIR/../../bin/download"
	}

	expected_output=$(
		cat <<-EOF
			asdf-php: Downloading PHP version 8.1.34 (cli, linux, x86_64)...
			asdf-php: Downloading php.ini-development file for PHP 8.1.34...
			asdf-php: Downloading php.ini-production file for PHP 8.1.34...
		EOF
	)

	run -0 download
	assert_output "$expected_output"
	assert_file_exists "$ASDF_DOWNLOAD_PATH/php"
	assert_file_exists "$ASDF_DOWNLOAD_PATH/php.ini-development"
	assert_file_exists "$ASDF_DOWNLOAD_PATH/php.ini-production"

	# The download command should remove the tarball after extraction.
	assert_file_not_exists "$ASDF_DOWNLOAD_PATH/php-8.1.34-cli-linux-x86_64.tar.gz"
}
