#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
	export DIR

	load '../../lib/composer.bash'

	# Mock the cd command.
	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	# Mock the rm command.
	rm() {
		[ "$1" = "composer-setup.php" ] && return 0
		fail "The rm command received unexpected arguments: ${*}"
	}

	# Mock the cp command.
	cp() {
		[ "$1" = "composer.phar" ] && [ "$2" = "/path/to/install/bin/composer" ] && return 0
		fail "The cp command received unexpected arguments: ${*}"
	}
}

teardown() {
	unset -f cd
	unset -f rm
	unset -f cp
}

@test "composer_download() executes with success" {
	/path/to/install/bin/php() {
		if [ "$1" = "-r" ]; then
			if [ "$2" = "copy('https://composer.github.io/installer.sig', 'php://stdout');" ] \
				|| [ "$2" = "echo hash_file('sha384', 'composer-setup.php');" ]; then
				printf "identical hash"
				return 0
			elif [ "$2" = "copy('https://getcomposer.org/installer', 'composer-setup.php');" ]; then
				return 0
			fi
		elif [ "$1" = "composer-setup.php" ] && [ "$2" = "--quiet" ]; then
			return 0
		fi

		fail "The php command received unexpected arguments: ${*}"
	}

	composer_download "/path/to/download" "/path/to/install"
}

@test "composer_download() executes with failure" {
	/path/to/install/bin/php() {
		if [ "$1" = "-r" ]; then
			if [ "$2" = "copy('https://composer.github.io/installer.sig', 'php://stdout');" ]; then
				printf "different hash one"
				return 0
			elif [ "$2" = "echo hash_file('sha384', 'composer-setup.php');" ]; then
				printf "different hash two"
				return 0
			elif [ "$2" = "copy('https://getcomposer.org/installer', 'composer-setup.php');" ]; then
				return 0
			fi
		fi

		fail "The php command received unexpected arguments: ${*}"
	}

	run ! composer_download "/path/to/download" "/path/to/install"
	assert_output "[ERROR] Invalid Composer installer checksum"
}

@test "composer_install() executes with success" {
	composer_install "/path/to/download" "/path/to/install"
}
