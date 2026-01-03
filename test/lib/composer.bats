#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	load '../../lib/composer.bash'

	cd() {
		[ "${*}" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	rm() {
		[ "${*}" = "composer-setup.php" ] && return 0
		fail "The rm command received unexpected arguments: ${*}"
	}

	cp() {
		[ "${*}" = "composer.phar /path/to/install/bin/composer" ] && return 0
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
		local expected1="-r copy('https://composer.github.io/installer.sig', 'php://stdout');"
		local expected2="-r echo hash_file('sha384', 'composer-setup.php');"
		local expected3="-r copy('https://getcomposer.org/installer', 'composer-setup.php');"
		local expected4="composer-setup.php --quiet"

		if [[ "${*}" = "$expected1" || "${*}" = "$expected2" ]]; then
			printf "this is a hash to compare"
			return 0
		elif [[ "${*}" = "$expected3" || "${*}" = "$expected4" ]]; then
			return 0
		fi

		fail "The php command received unexpected arguments: ${*}"
	}

	composer_download "/path/to/download" "/path/to/install"

	unset -f /path/to/install/bin/php
}

@test "composer_download() executes with failure" {
	/path/to/install/bin/php() {
		local expected1="-r copy('https://composer.github.io/installer.sig', 'php://stdout');"
		local expected2="-r echo hash_file('sha384', 'composer-setup.php');"
		local expected3="-r copy('https://getcomposer.org/installer', 'composer-setup.php');"

		if [[ "${*}" = "$expected1" ]]; then
			printf "this is a hash downloaded from installer.sig"
			return 0
		elif [[ "${*}" = "$expected2" ]]; then
			printf "this is a different hash produced locally from composer-setup.php"
			return 0
		elif [[ "${*}" = "$expected3" ]]; then
			return 0
		fi

		fail "The php command received unexpected arguments: ${*}"
	}

	run ! composer_download "/path/to/download" "/path/to/install"
	assert_output "[ERROR] Invalid Composer installer checksum"

	unset -f /path/to/install/bin/php
}

@test "composer_install() executes with success" {
	composer_install "/path/to/download" "/path/to/install"
}
