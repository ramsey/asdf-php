#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	load '../../lib/download.bash'
}

@test "download_release() succeeds" {
	curl() {
		local expected1="-fsSL -o /path/to/download/php-8.3.0-cli-test_os-test_arch.tar.gz -C - https://dl.static-php.dev/static-php-cli/bulk/php-8.3.0-cli-test_os-test_arch.tar.gz"
		local expected2="-fsSL -o /path/to/download/php.ini-development -C - https://github.com/php/php-src/raw/refs/tags/php-8.3.0/php.ini-development"
		local expected3="-fsSL -o /path/to/download/php.ini-production -C - https://github.com/php/php-src/raw/refs/tags/php-8.3.0/php.ini-production"

		if [[ "${*}" = "$expected1" || "${*}" = "$expected2" || "${*}" = "$expected3" ]]; then
			return 0
		fi

		fail "The curl command received unexpected arguments: ${*}"
	}

	tar() {
		if [[ "${*}" = "-xzf /path/to/download/php-8.3.0-cli-test_os-test_arch.tar.gz -C /path/to/download" ]]; then
			return 0
		fi

		fail "The tar command received unexpected arguments: ${*}"
	}

	rm() {
		if [[ "${*}" = "/path/to/download/php-8.3.0-cli-test_os-test_arch.tar.gz" ]]; then
			return 0
		else
			fail "The rm command received unexpected arguments: ${*}"
		fi
	}

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Downloading PHP version 8.3.0 (cli, test_os, test_arch)...
			asdf-php: Downloading php.ini-development file for PHP 8.3.0...
			asdf-php: Downloading php.ini-production file for PHP 8.3.0...
		EOF
	)

	run download_release 8.3.0 /path/to/download test_os test_arch
	assert_output "$expected_output"

	unset -f curl
	unset -f tar
	unset -f rm
}

@test "download_release() when it fails to download tarball" {
	curl() {
		return 1
	}

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Downloading PHP version 3.0.0 (cli, test_os, test_arch)...
			asdf-php: Could not download https://dl.static-php.dev/static-php-cli/bulk/php-3.0.0-cli-test_os-test_arch.tar.gz
		EOF
	)

	run ! download_release 3.0.0 /path/to/download test_os test_arch
	assert_output "$expected_output"

	unset -f curl
}

@test "download_release() when it fails to unpack tarball" {
	curl() {
		local expected1="-fsSL -o /path/to/download/php-8.1.34-cli-test_os-test_arch.tar.gz -C - https://dl.static-php.dev/static-php-cli/bulk/php-8.1.34-cli-test_os-test_arch.tar.gz"

		if [[ "${*}" = "$expected1" ]]; then
			return 0
		fi

		fail "The curl command received unexpected arguments: ${*}"
	}

	tar() {
		return 1
	}

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Downloading PHP version 8.1.34 (cli, test_os, test_arch)...
			asdf-php: Could not extract /path/to/download/php-8.1.34-cli-test_os-test_arch.tar.gz
		EOF
	)

	run ! download_release 8.1.34 /path/to/download test_os test_arch
	assert_output "$expected_output"

	unset -f curl
	unset -f tar
}

@test "download_release() when it fails to download development INI file" {
	curl() {
		local expected1="-fsSL -o /path/to/download/php-8.4.1-cli-test_os-test_arch.tar.gz -C - https://dl.static-php.dev/static-php-cli/bulk/php-8.4.1-cli-test_os-test_arch.tar.gz"
		local expected2="-fsSL -o /path/to/download/php.ini-development -C - https://github.com/php/php-src/raw/refs/tags/php-8.4.1/php.ini-development"

		if [[ "${*}" = "$expected1" ]]; then
			return 0
		elif [[ "${*}" = "$expected2" ]]; then
			return 1
		fi

		fail "The curl command received unexpected arguments: ${*}"
	}

	tar() {
		return 0
	}

	rm() {
		return 0
	}

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Downloading PHP version 8.4.1 (cli, test_os, test_arch)...
			asdf-php: Downloading php.ini-development file for PHP 8.4.1...
			asdf-php: Could not download https://github.com/php/php-src/raw/refs/tags/php-8.4.1/php.ini-development
		EOF
	)

	run ! download_release 8.4.1 /path/to/download test_os test_arch
	assert_output "$expected_output"

	unset -f curl
	unset -f tar
	unset -f rm
}

@test "download_release() when it fails to download production INI file" {
	curl() {
		local expected1="-fsSL -o /path/to/download/php-8.4.3-cli-test_os-test_arch.tar.gz -C - https://dl.static-php.dev/static-php-cli/bulk/php-8.4.3-cli-test_os-test_arch.tar.gz"
		local expected2="-fsSL -o /path/to/download/php.ini-development -C - https://github.com/php/php-src/raw/refs/tags/php-8.4.3/php.ini-development"
		local expected3="-fsSL -o /path/to/download/php.ini-production -C - https://github.com/php/php-src/raw/refs/tags/php-8.4.3/php.ini-production"

		if [[ "${*}" = "$expected1" || "${*}" = "$expected2" ]]; then
			return 0
		elif [[ "${*}" = "$expected3" ]]; then
			return 1
		fi

		fail "The curl command received unexpected arguments: ${*}"
	}

	tar() {
		return 0
	}

	rm() {
		return 0
	}

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Downloading PHP version 8.4.3 (cli, test_os, test_arch)...
			asdf-php: Downloading php.ini-development file for PHP 8.4.3...
			asdf-php: Downloading php.ini-production file for PHP 8.4.3...
			asdf-php: Could not download https://github.com/php/php-src/raw/refs/tags/php-8.4.3/php.ini-production
		EOF
	)

	run ! download_release 8.4.3 /path/to/download test_os test_arch
	assert_output "$expected_output"

	unset -f curl
	unset -f tar
	unset -f rm
}

@test "download_release() succeeds with ASDF_PHP_FPM=yes" {
	curl() {
		local expected1="-fsSL -o /path/to/download/php-8.3.0-cli-test_os-test_arch.tar.gz -C - https://dl.static-php.dev/static-php-cli/bulk/php-8.3.0-cli-test_os-test_arch.tar.gz"
		local expected2="-fsSL -o /path/to/download/php-8.3.0-fpm-test_os-test_arch.tar.gz -C - https://dl.static-php.dev/static-php-cli/bulk/php-8.3.0-fpm-test_os-test_arch.tar.gz"
		local expected3="-fsSL -o /path/to/download/php.ini-development -C - https://github.com/php/php-src/raw/refs/tags/php-8.3.0/php.ini-development"
		local expected4="-fsSL -o /path/to/download/php.ini-production -C - https://github.com/php/php-src/raw/refs/tags/php-8.3.0/php.ini-production"

		if [[ "${*}" = "$expected1" || "${*}" = "$expected2" || "${*}" = "$expected3" || "${*}" = "$expected4" ]]; then
			return 0
		fi

		fail "The curl command received unexpected arguments: ${*}"
	}

	tar() {
		local expected1="-xzf /path/to/download/php-8.3.0-cli-test_os-test_arch.tar.gz -C /path/to/download"
		local expected2="-xzf /path/to/download/php-8.3.0-fpm-test_os-test_arch.tar.gz -C /path/to/download"

		if [[ "${*}" = "$expected1" || "${*}" = "$expected2" ]]; then
			return 0
		fi

		fail "The tar command received unexpected arguments: ${*}"
	}

	rm() {
		local expected1="/path/to/download/php-8.3.0-cli-test_os-test_arch.tar.gz"
		local expected2="/path/to/download/php-8.3.0-fpm-test_os-test_arch.tar.gz"

		if [[ "${*}" = "$expected1" || "${*}" = "$expected2" ]]; then
			return 0
		else
			fail "The rm command received unexpected arguments: ${*}"
		fi
	}

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Downloading PHP version 8.3.0 (cli, test_os, test_arch)...
			asdf-php: Downloading PHP version 8.3.0 (fpm, test_os, test_arch)...
			asdf-php: Downloading php.ini-development file for PHP 8.3.0...
			asdf-php: Downloading php.ini-production file for PHP 8.3.0...
		EOF
	)

	export ASDF_PHP_FPM=yes

	run download_release 8.3.0 /path/to/download test_os test_arch
	assert_output "$expected_output"

	unset -f curl
	unset -f tar
	unset -f rm
	unset -v ASDF_PHP_FPM
}
