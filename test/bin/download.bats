#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# If the directory already exists, remove it.
	local download_path=/tmp/asdf-php-test
	if [ -d "$download_path" ]; then
		rm -rf "$download_path"
	fi

	ASDF_DOWNLOAD_PATH="$download_path"
}

@test "download command could not download file" {
	ASDF_INSTALL_VERSION=3.0.0

	# A mock for the curl command.
	# shellcheck disable=SC2317
	curl() {
		return 1
	}

	# shellcheck disable=SC2317
	download() {
		# shellcheck source=../../bin/download
		source "$DIR/../../bin/download"
	}

	expected_output=$(
		cat <<-EOF
			asdf-php: Downloading PHP version $ASDF_INSTALL_VERSION...
			asdf-php: Could not download https://www.php.net/distributions/php-$ASDF_INSTALL_VERSION.tar.gz
		EOF
	)

	run ! download
	assert_output "$expected_output"
	[ -d "$ASDF_DOWNLOAD_PATH" ]
}

@test "download command could not extract file" {
	ASDF_INSTALL_VERSION=8.3.0

	# A mock for the curl command.
	# shellcheck disable=SC2317
	curl() {
		cp "$DIR"/../fixtures/foo.tar.gz.invalid "$3"
	}

	# shellcheck disable=SC2317
	download() {
		# shellcheck source=../../bin/download
		source "$DIR/../../bin/download"
	}

	expected_output=$(
		cat <<-EOF
			asdf-php: Downloading PHP version 8.3.0...
			asdf-php: Could not extract $ASDF_DOWNLOAD_PATH/php-$ASDF_INSTALL_VERSION.tar.gz
		EOF
	)

	run download
	assert_output "$expected_output"
	[ -d "$ASDF_DOWNLOAD_PATH" ]

	# Downloaded file remains in place, in case the user needs to debug it.
	[ -f "$ASDF_DOWNLOAD_PATH/php-$ASDF_INSTALL_VERSION.tar.gz" ]
}

# bats test_tags=integration
@test "download command downloads and extracts file" {
	ASDF_INSTALL_VERSION=8.1.27

	# shellcheck disable=SC2317
	download() {
		# shellcheck source=../../bin/download
		source "$DIR/../../bin/download"
	}

	expected_output=$(
		cat <<-EOF
			asdf-php: Downloading PHP version $ASDF_INSTALL_VERSION...
		EOF
	)

	run download
	assert_output "$expected_output"
	[ -d "$ASDF_DOWNLOAD_PATH" ]

	# The download command should remove the tarball after extraction.
	[ ! -f "$ASDF_DOWNLOAD_PATH/php-$ASDF_INSTALL_VERSION.tar.gz" ]

	# Check the contents of the NEWS file to make sure it's what we expect.
	expected_NEWS="$(cat "$DIR/../fixtures/NEWS-php-$ASDF_INSTALL_VERSION")"
	actual_NEWS="$(cat "$ASDF_DOWNLOAD_PATH/NEWS")"
	[ "$actual_NEWS" = "$expected_NEWS" ]
}
