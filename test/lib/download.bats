#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	load '../../lib/download.bash'
}

@test "download_release() with version" {
	# A mock for the curl command.
	# shellcheck disable=SC2317
	curl() {
		if [ "$1" != '-fsSL' ]; then
			fail "Expected curl options -fsSL; received $1"
		fi

		if [ "$2" != '-o' ]; then
			fail "Expected curl option -o"
		fi

		if [ "$3" != 'php.tar.gz' ]; then
			fail "Expected php.tar.gz as value of curl option -o; received $3"
		fi

		if [ "$4" != '-C' ]; then
			fail "Expected curl option -C; received $4"
		fi

		if [ "$5" != '-' ]; then
			fail "Expected curl option -; received $5"
		fi

		if [ "$6" != 'https://www.php.net/distributions/php-8.3.0.tar.gz' ]; then
			fail "Expected URL https://www.php.net/distributions/php-8.3.0.tar.gz; received $6"
		fi

		return 0
	}

	run download_release 8.3.0 php.tar.gz
	assert_output "asdf-php: Downloading PHP version 8.3.0..."
}

@test "download_release() with ref" {
	# A mock for the curl command.
	# shellcheck disable=SC2317
	curl() {
		if [ "$1" != '-fsSL' ]; then
			fail "Expected curl options -fsSL; received $1"
		fi

		if [ "$2" != '-o' ]; then
			fail "Expected curl option -o"
		fi

		if [ "$3" != 'php-branch-name.tar.gz' ]; then
			fail "Expected php-branch-name.tar.gz as value of curl option -o; received $3"
		fi

		if [ "$4" != '-C' ]; then
			fail "Expected curl option -C; received $4"
		fi

		if [ "$5" != '-' ]; then
			fail "Expected curl option -; received $5"
		fi

		if [ "$6" != 'https://github.com/php/php-src/archive/branch-name.tar.gz' ]; then
			fail "Expected URL https://github.com/php/php-src/archive/branch-name.tar.gz; received $6"
		fi

		return 0
	}

	export ASDF_INSTALL_TYPE="ref"
	run download_release branch-name php-branch-name.tar.gz
	assert_output "asdf-php: Downloading PHP ref branch-name..."
}

@test "download_release() failure" {
	# A mock for the curl command.
	curl() {
		return 1
	}

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Downloading PHP version 3.0.0...
			asdf-php: Could not download https://www.php.net/distributions/php-3.0.0.tar.gz
		EOF
	)

	run ! download_release 3.0.0 php.tar.gz
	assert_output "$expected_output"
}
