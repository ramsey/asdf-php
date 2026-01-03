#!/usr/bin/env bash

set -euo pipefail

current_script_path=$(realpath "${BASH_SOURCE[0]}")
plugin_dir=$(realpath "$(dirname "$(dirname "$current_script_path")")")

# shellcheck source=utils.bash
. "${plugin_dir}/lib/utils.bash"

# shellcheck source=composer.bash
. "${plugin_dir}/lib/composer.bash"

# Installs a version of PHP to the given path.
#
# Arguments:
#   version - The PHP version to install.
#   download_path - The path to which PHP was downloaded.
#   install_path - The path at which to install PHP.
install_version() {
	local version="$1"
	local download_path="$2"
	local install_path="$3"

	(
		mkdir -p "$install_path/bin" || exit 2

		php_install "$download_path" "$install_path" || exit 3

		test -x "$install_path/bin/php" || asdf_fail "Expected $install_path/bin/php to be executable."

		php_ini_install "$download_path" "$install_path" || exit 5
		php_composer_install "$download_path" "$install_path" || exit 7

		test -x "$install_path/bin/composer" || asdf_fail "Expected $install_path/bin/composer to be executable."

		printf "\n" | asdf_log
		"$install_path/bin/php" --version | asdf_log || exit 11
		printf "\n" | asdf_log

		if [[ -x "$install_path/bin/php-fpm" ]]; then
			"$install_path/bin/php-fpm" --version | asdf_log || exit 13
			printf "\n" | asdf_log
		fi

		config_files=$(
			PHPRC="$install_path/etc/php/php.ini" \
				PHP_INI_SCAN_DIR="$install_path/etc/php/conf.d" \
				"$install_path/bin/php" --ini | tail -n+2
		)

		printf "%s\n" "$config_files" | asdf_log
		printf "\n" | asdf_log

		"$install_path/bin/php" "$install_path/bin/composer" --version | asdf_log || exit 17
		printf "\n" | asdf_log

		asdf_info "PHP $version installation was successful!"
	) || (
		local status=$?
		if [ -d "$install_path" ]; then
			rm -rf "$install_path"
		fi
		asdf_fail "An error occurred while installing PHP $version." "$status"
	)
}

# Installs the static PHP binary.
#
# Arguments:
#   download_path - The path where the static PHP binary was downloaded and unpacked.
#   install_path - The path to which this version of PHP should be installed.
php_install() {
	local download_path="$1"
	local install_path="$2"

	local php_binary="${download_path}/php"
	local php_fpm_binary="${download_path}/php-fpm"

	cd "$download_path"

	asdf_info "Installing PHP to $install_path"

	test -d "$download_path" || asdf_fail "Download directory ${download_path} does not exist."
	test -d "$install_path" || asdf_fail "Installation directory ${install_path} does not exist."
	test -x "$php_binary" || asdf_fail "Unable to find ${php_binary}"

	cp "$php_binary" "${install_path}/bin/php"

	# The php-fpm binary might not exist, e.g., if ASDF_PHP_FPM is not set.
	if [[ -x "$php_fpm_binary" ]]; then
		cp "$php_fpm_binary" "${install_path}/bin/php-fpm"
	fi
}

# Installs the PHP INI file(s).
#
# Arguments:
#   download_path - The path where the static PHP INI files were downloaded.
#   install_path - The path to which the PHP INI files should be installed.
php_ini_install() {
	local download_path="$1"
	local install_path="$2"

	local php_ini_development="${download_path}/php.ini-development"
	local php_ini_production="${download_path}/php.ini-production"

	cd "$download_path"

	asdf_info "Installing PHP INI files to $install_path"

	test -d "$download_path" || asdf_fail "Download directory ${download_path} does not exist."
	test -d "$install_path" || asdf_fail "Installation directory ${install_path} does not exist."
	test -f "$php_ini_development" || asdf_fail "Unable to find ${php_ini_development}"
	test -f "$php_ini_production" || asdf_fail "Unable to find ${php_ini_production}"

	local php_ini_path="${install_path}/etc/php"
	local php_ini_scan_path="${php_ini_path}/conf.d"

	# Execute once with -p creates intermediate directories, as well.
	mkdir -p "${php_ini_scan_path}" || asdf_fail "Unable to create directory ${php_ini_scan_path}"

	cp "$php_ini_development" "${php_ini_path}/php.ini-development"
	cp "$php_ini_production" "${php_ini_path}/php.ini-production"

	# Initialize the installation with the development version.
	cp "$php_ini_development" "${php_ini_path}/php.ini"
}

# Downloads and installs Composer.
#
# Arguments:
#   download_path - The path where the PHP source was downloaded and unpacked.
#   install_path - The path to which Composer should be installed (which is usually the same place PHP was installed).
php_composer_install() {
	local download_path="$1"
	local install_path="$2"
	local composer_home="${install_path}/composer"

	asdf_info "Installing Composer to $install_path"

	composer_download "$download_path" "$install_path" || asdf_fail "Failed to download Composer"
	composer_install "$download_path" "$install_path" || asdf_fail "Failed to install Composer"

	mkdir -p "${composer_home}" || asdf_fail "Unable to create directory ${composer_home}"
}
