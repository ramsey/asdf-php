#!/usr/bin/env bash

set -euo pipefail

# Downloads Composer for a specific PHP installation.
#
# Adapted from https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
#
# Arguments:
#   The path to use when downloading Composer.
#   The installation path for the version of PHP associated with this Composer.
composer_download() {
	local download_path="$1"
	local install_path="$2"

	local php="$install_path/bin/php"
	local expected_checksum actual_checksum

	cd "$download_path"
	expected_checksum="$("$php" -r "copy('https://composer.github.io/installer.sig', 'php://stdout');")"
	"$php" -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	actual_checksum="$("$php" -r "echo hash_file('sha384', 'composer-setup.php');")"

	if [ "$expected_checksum" != "$actual_checksum" ]; then
		printf "[ERROR] Invalid Composer installer checksum\n" >&2
		rm composer-setup.php
		return 1
	fi

	"$php" composer-setup.php --quiet
	local result=$?
	rm composer-setup.php
	return $result
}

# Installs Composer for a specific PHP installation.
#
# Arguments:
#   The path where Composer was downloaded.
#   The installation path for the version of PHP associated with this Composer.
composer_install() {
	local download_path="$1"
	local install_path="$2"

	cd "$download_path"
	cp composer.phar "$install_path/bin/composer"
}
