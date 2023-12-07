#!/usr/bin/env bash

set -euo pipefail

current_script_path=$(realpath "${BASH_SOURCE[0]}")
plugin_dir=$(realpath "$(dirname "$(dirname "$current_script_path")")")

# shellcheck source=utils.bash
. "${plugin_dir}/lib/utils.bash"

# shellcheck source=composer.bash
. "${plugin_dir}/lib/composer.bash"

# Set EXTRA_CFLAGS to "-w" only if it is not set.
# If it is set but empty, allow the empty value.
export EXTRA_CFLAGS="${EXTRA_CFLAGS--w}"
export EXTRA_LDFLAGS="${EXTRA_LDFLAGS:-}"

apt_path=
brew_path=
dnf_path=
gcc_path=
gxx_path=
is_mac_os=no
log_file=
make_path=

declare -a configure_options=()
declare -a error_messages=()

# Since macOS uses a very old version of Bash, we'll fake associative arrays.
declare -a missing_required_commands__keys=()
declare -a missing_required_commands__values=()
declare -a missing_required_packages__keys=()
declare -a missing_required_packages__values=()
declare -a missing_optional_packages__keys=()
declare -a missing_optional_packages__values=()

# Downloads, builds, and installs the given version of PHP.
#
# Arguments:
#   The type of installation (i.e., "version" or "ref").
install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="$3"

	local download_path="$ASDF_DOWNLOAD_PATH"

	(
		ensure_log_file || exit 9

		mkdir -p "$install_path" || exit 11

		php_preflight_checks "$download_path" || exit 21

		# If installing from a ref, then we need to run buildconf. Otherwise,
		# distribution packages of PHP already contain the configure script.
		if [ "${install_type:-version}" = "ref" ]; then
			php_buildconf "$download_path" || exit 31
		fi

		php_configure "$download_path" "$install_path" || exit 41
		php_make_install "$download_path" "$install_path" || exit 51
		php_composer_install "$download_path" "$install_path" || exit 61

		test -x "$install_path/bin/php" || asdf_fail "Expected $install_path/bin/php to be executable." 71

		printf "\n" | asdf_log
		"$install_path/bin/php" --version | asdf_log || exit 81
		printf "\n" | asdf_log
		"$install_path/bin/php" "$install_path/bin/composer" --version | asdf_log || exit 91
		printf "\n" | asdf_log

		asdf_info "$tool_name $version installation was successful!"
	) || (
		local status=$?
		if [ -d "$install_path" ]; then
			rm -rf "$install_path"
		fi
		asdf_fail "An error occurred while installing $tool_name $version." "$status"
	)
}

# Checks the system to ensure it has the commands necessary to build and install PHP.
#
# Arguments:
#   The path where the PHP source was downloaded and unpacked.
php_preflight_checks() {
	local download_path="$1"
	cd "$download_path"

	apt_path="$(command -v apt-get || true)"
	brew_path="$(command -v brew || true)"
	dnf_path="$(command -v dnf || true)"
	[[ "$(uname -a)" =~ "Darwin" ]] && is_mac_os=yes

	check_autoconf
	check_bison
	check_g++
	check_gcc
	check_make
	check_pkg_config
	check_re2c

	if is_truthy "$is_mac_os"; then
		export EXTRA_LDFLAGS="-Wl,-ld_classic${EXTRA_LDFLAGS:+,${EXTRA_LDFLAGS}}"
	fi

	if is_missing_required_commands; then
		print_missing_required_commands_table
		print_missing_packages_installation "required"
		asdf_fail "Failed to install $tool_name; see the message above for details."
	fi
}

# Runs buildconf to generate the PHP configure script.
#
# Arguments:
#   The path where the PHP source was downloaded and unpacked.
php_buildconf() {
	local download_path="$1"

	asdf_info "Running buildconf to configure the build"

	cd "$download_path"
	"./buildconf" --force || asdf_fail "Buildconf failed"
}

# Inspects the system for dependencies and configures PHP for building.
#
# Arguments:
#   The path where the PHP source was downloaded and unpacked.
#   The path to which this version of PHP should be installed after building.
#   The path to a location where build logs are written.
php_configure() {
	local download_path="$1"
	local install_path="$2"

	add_option "--prefix=${install_path}"
	add_option "--with-layout=GNU"
	add_option "--with-config-file-path=${install_path}/etc"
	add_option "--with-config-file-scan-dir=${install_path}/etc/php.d"
	add_option "--disable-option-checking"

	add_option_php_fpm

	add_option "--enable-bcmath"
	add_option "--enable-calendar"
	add_option "--enable-dba"
	add_option "--enable-exif"
	add_option "--enable-ftp"
	add_option "--enable-inifile"
	add_option "--enable-mbstring"
	add_option "--enable-pcntl"
	add_option "--enable-pdo"
	add_option "--enable-shmop"
	add_option "--enable-sockets"
	add_option "--enable-sysvmsg"
	add_option "--enable-sysvsem"
	add_option "--enable-sysvshm"
	add_option "--with-cdb"
	add_option "--with-mhash"
	add_option "--with-mysqli=mysqlnd"
	add_option "--with-pcre-jit"
	add_option "--with-pdo-mysql=mysqlnd"

	if should_install_without_pear; then
		add_option "--without-pear"
	else
		add_option "--with-pear"
	fi

	# Add options from lib/options.tsv.
	# To allow empty columns in the tab-separated values file, we convert tab
	# characters to the ASCII unit separator character and then split the line
	# on the unit separator.
	local tmp_dir options_file
	tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'tmp_dir')
	options_file="${tmp_dir}/options.tsv"
	tr \\t \\037 <"${plugin_dir}/lib/options.tsv" >"$options_file"

	local name packages pkg header option description required
	while IFS=$'\037' read -r name packages pkg header option description required; do
		# Skip the header row
		if [ "$name" = "common name" ]; then
			continue
		fi

		if [ -n "$header" ]; then
			add_option_header "$name" "$packages" "$header" "$option" "$description" "$required"
		else
			add_option_pkg_config "$name" "$packages" "$pkg" "$option" "$description" "$required"
		fi
	done <"$options_file"

	if is_missing_required_packages; then
		print_missing_packages_table "required"
		print_missing_packages_installation "required"
		asdf_fail "Failed to install $tool_name; see the message above for details."
	fi

	if is_missing_optional_packages; then
		print_missing_packages_table "optional"
		print_missing_packages_installation "optional"
		asdf_info "Missing some optional packages; see above."
		printf "\n  Use Ctrl-C to cancel the build and install these, if you wish to include them.\n\n" | asdf_log
	fi

	asdf_info "Configuring the build (this can take a while)..."
	asdf_info "To view build progress, tail -f $log_file"

	log <<-EOF
		Changing directory to ${download_path}
		CC=${gcc_path} CXX="${gxx_path} ./configure ${configure_options[*]-}
	EOF

	cd "$download_path"
	CC="${gcc_path}" CXX="${gxx_path}" "./configure" "${configure_options[@]-}" 2>&1 | log \
		|| asdf_fail "Failed to configure $tool_name; for details, see $log_file"
}

# Builds and installs PHP.
#
# Arguments:
#   The path where the PHP source was downloaded and unpacked.
#   The path to which this version of PHP should be installed after building.
php_make_install() {
	local download_path="$1"
	local install_path="$2"
	local make_flags="-j${ASDF_CONCURRENCY:-$(getconf _NPROCESSORS_ONLN)}"

	cd "$download_path"

	asdf_info "Building $tool_name (this can take a while)..."

	"$make_path" "CC=$gcc_path" "CXX=$gxx_path" "EXTRA_CFLAGS=$EXTRA_CFLAGS" "EXTRA_LDFLAGS=$EXTRA_LDFLAGS" "$make_flags" 2>&1 | log \
		|| asdf_fail "Failed to build $tool_name; for details, see $log_file"

	asdf_info "Installing $tool_name to $install_path"

	"$make_path" "CC=$gcc_path" "CXX=$gxx_path" "EXTRA_CFLAGS=$EXTRA_CFLAGS" "EXTRA_LDFLAGS=$EXTRA_LDFLAGS" "$make_flags" install 2>&1 | log \
		|| asdf_fail "Failed to install $tool_name; for details, see $log_file"

	mkdir -p "${install_path}/etc/php.d"
	cp "${download_path}/php.ini-development" "${install_path}/etc/php.ini"
}

# Downloads and installs Composer.
#
# Arguments:
#   The path where the PHP source was downloaded and unpacked.
#   The path to which Composer should be installed (which is usually the same place PHP was installed).
php_composer_install() {
	local download_path="$1"
	local install_path="$2"

	asdf_info "Installing Composer to $install_path"

	composer_download "$download_path" "$install_path" || asdf_fail "Failed to download Composer"
	composer_install "$download_path" "$install_path" || asdf_fail "Failed to install Composer"
}

# Add a simple PHP configuration option for functionality that is bundled within
# PHP.
#
# Do not use this to add options for features that require external dependencies.
#
# Example:
#
#     add_option "--enable-bcmath"
#
# Arguments:
#   Option name (i.e., "--enable-bcmath")
add_option() {
	local index="${#configure_options[@]}"
	configure_options["$index"]="$1"
}

# Add a PHP configuration option that includes a path for looking up the header file.
#
# Example:
#
#     add_option_header \
#         "bzip2" \
#         "bzip2 libbz2-dev bzip2-devel" \
#         "bzlib.h" \
#         "--with-bz2" \
#         "Includes bzip2 compression support" \
#         "required"
#
# Arguments:
#   A common name for the package providing the feature
#   Space-separated list of package names for package managers in the order "brew apt dnf" (i.e., "bzip2 libbz2-dev bzip2-devel")
#   Header file name(s), space-separated if more than one (i.e., "bzlib.h")
#   Option name (i.e., "--with-bz2")
#   Description to print for missing required or optional package
#   Whether the package is required (i.e., "required" or "optional")
add_option_header() {
	local common_name="$1"
	local package_names="$2"

	local header_files
	read -r -a header_files <<<"$3"

	local option="$4"
	local description="$5"
	local state="$6"

	local package_name=""
	package_name="$(get_package_name "$common_name" "$package_names")"

	local additional_lookup_location=""
	if [ -n "$brew_path" ]; then
		additional_lookup_location="$("$brew_path" --prefix "$package_name" || true)"
	fi

	# Figure out the location we will tell PHP to use to look up the library's
	# header file. If we can't find one, we'll log the package as missing.
	local header_location=""
	header_location="$(header_file_location "${header_files[*]}" "$additional_lookup_location" || true)"

	if [ -n "$header_location" ]; then
		# We need a special case for --with-iconv. If the header location is in
		# a standard location (i.e., /usr or /usr/local), we won't provide a
		# search prefix, since PHP is able to find it, and especially since
		# iconv could be provided by glibc, in which case PHP can't find it if
		# we provide the search prefix. If the search prefix is other than
		# /usr or /usr/local, then we probably found iconv with Homebrew and
		# should use the search prefix so PHP can find it.
		if [[ "$option" == --with-iconv* && ("$header_location" = "/usr" || "$header_location" = "/usr/local") ]]; then
			add_option "${option//=/}"
		elif [[ "$option" == *= ]]; then
			add_option "${option}${header_location}"
		else
			add_option "${option}"
		fi
	elif [ "$state" = "required" ]; then
		missing_required_package "$package_name" "$description"
	else
		missing_optional_package "$package_name" "$description"
	fi
}

# Adds PHP configure options for php-fpm support.
add_option_php_fpm() {
	local fpm_user

	if id _www >/dev/null 2>&1; then
		fpm_user="_www"
	elif id www-data >/dev/null 2>&1; then
		fpm_user="www-data"
	else
		fpm_user="nobody"
	fi

	add_option "--enable-fpm"
	add_option "--with-fpm-user=${fpm_user}"
	add_option "--with-fpm-group=${fpm_user}"
}

# Add a PHP configuration option that will look up dependencies using pkg-config.
#
# Example:
#
#     add_option_pkg_config \
#         "curl" \
#         "curl libcurl4-openssl-dev libcurl-devel" \
#         "libcurl" \
#         "--with-curl" \
#         "Includes cURL support" \
#         "required"
#
# Arguments:
#   A common name for the package providing the feature
#   Space-separated list of package names for package managers in the order "brew apt dnf" (i.e., "curl libcurl4-openssl-dev libcurl-devel")
#   The library name used for looking up the package with pkg-config
#   One or more options, separated by spaces (i.e., "--with-curl"); if any option ends with an equals symbol, this will append the prefix where the package is located (e.g., /usr, /usr/local, etc.)
#   Description to print for missing required or optional package
#   Whether the package is required (i.e., "required" or "optional")
add_option_pkg_config() {
	local common_name="$1"
	local package_names="$2"
	local library="$3"

	local options
	read -r -a options <<<"$4"

	local description="$5"
	local state="$6"

	local package_name
	package_name="$(get_package_name "$common_name" "$package_names")"

	# Use a special condition for readline. If readline is present, we'll use it.
	# Otherwise, we'll use libedit, which was passed to this function.
	if [ "$common_name" = "readline" ] && use_readline; then
		return
	fi

	update_pkg_config_path "$package_name"

	if pkg-config --exists "${library}"; then
		local prefix
		prefix="$(pkg-config --variable=prefix "${library}")"

		local option
		for option in "${options[@]}"; do
			# We need a special case for --with-gmp. If the header location is
			# in a standard location (i.e., /usr or /usr/local), we won't
			# provide a search prefix, since PHP is able to find it, and
			# especially since gmp could be in an architecture-specific location,
			# in which case PHP can't find it if we provide the search prefix.
			# If the search prefix is other than /usr or /usr/local, then we
			# probably found gmp with Homebrew and should use the search prefix
			# so PHP can find it.
			if [[ "$option" == --with-gmp* && ("$prefix" = "/usr" || "$prefix" = "/usr/local") ]]; then
				add_option "${option//=/}"
			# Include a special condition for "--with-pdo-odbc=unixODBC,".
			elif [[ "$option" == *= ]] || [[ "$option" == *=unixODBC, ]]; then
				add_option "${option}${prefix}"
			else
				add_option "${option}"
			fi
		done
	elif [ "$state" = "required" ]; then
		missing_required_package "$package_name" "$description"
	else
		missing_optional_package "$package_name" "$description"
	fi
}

# Checks whether the system has autoconf installed.
check_autoconf() {
	if ! command -v autoconf >/dev/null; then
		missing_required_command autoconf "Produces configure scripts"
		missing_required_package autoconf
	fi
}

# Checks whether the system has bison installed.
check_bison() {
	if ! command -v bison >/dev/null; then
		missing_required_command bison "Generates parsers"
		missing_required_package bison
	fi
}

# Checks whether the system has g++ installed.
check_g++() {
	# Check to see whether any newer versions of g++ are installed.
	#gxx_path="$(command -v g++-14)" \
	#	|| gxx_path="$(command -v g++-13)" \
	#	|| gxx_path="$(command -v g++-12)" \
	#	|| gxx_path="$(command -v g++-11)" \
	#	|| gxx_path="$(command -v g++-10)" \
	#	|| gxx_path="$(command -v g++)" \
	#	|| gxx_path=""
	gxx_path="$(command -v g++)" \
		|| gxx_path=""

	if [ -z "$gxx_path" ]; then
		missing_required_command g++ "Compiles C++ code"

		if [ -n "$brew_path" ]; then
			# Homebrew includes g++ in the gcc package.
			missing_required_package gcc
		else
			missing_required_package g++
		fi

		if is_truthy "$is_mac_os"; then
			error_message "On macOS, you may need to install the Command Line Tools for Xcode."
		fi
	fi
}

# Checks whether the system has gcc installed.
check_gcc() {
	# Check to see whether any newer versions of gcc are installed.
	#gcc_path="$(command -v gcc-14)" \
	#	|| gcc_path="$(command -v gcc-13)" \
	#	|| gcc_path="$(command -v gcc-12)" \
	#	|| gcc_path="$(command -v gcc-11)" \
	#	|| gcc_path="$(command -v gcc-10)" \
	#	|| gcc_path="$(command -v gcc)" \
	#	|| gcc_path=""
	gcc_path="$(command -v gcc)" \
		|| gcc_path=""

	if [ -z "$gcc_path" ]; then
		missing_required_command gcc "Compiles C code"
		missing_required_package gcc

		if is_truthy "$is_mac_os"; then
			error_message "On macOS, you may need to install the Command Line Tools for Xcode."
		fi
	fi
}

# Checks whether the system has make installed.
check_make() {
	# Check to see whether gmake (e.g., make via Homebrew) is installed.
	make_path="$(command -v gmake)" \
		|| make_path="$(command -v make)" \
		|| make_path=""

	if [ -z "$make_path" ]; then
		missing_required_command make "Build automation tooling"
		missing_required_package make

		if is_truthy "$is_mac_os"; then
			error_message "On macOS, you may need to install the Command Line Tools for Xcode."
		fi
	fi
}

# Checks whether the system has pkg-config installed.
check_pkg_config() {
	if ! command -v pkg-config >/dev/null; then
		missing_required_command pkg-config "Queries installed libraries"
		missing_required_package pkg-config
	fi
}

# Checks whether the system has re2c installed.
check_re2c() {
	if ! command -v re2c >/dev/null; then
		missing_required_command re2c "Generates lexers"
		missing_required_package re2c
	fi
}

# If log_file is not set or does not exist, then set it and create it.
ensure_log_file() {
	if [ -n "$log_file" ] && [ -f "$log_file" ]; then
		return
	fi

	# Create a tmp directory for storing build log files.
	local log_dir
	log_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'log_dir')

	# Set the global log_file value.
	log_file="${log_dir}/asdf-php-build.log"

	# Create an empty log file at the location.
	truncate -s 0 "$log_file" || asdf_fail "Unable to create log file at {$log_file}"
}

# Stores an additional error message to the error_messages array.
#
# Arguments:
#   The error message to store.
error_message() {
	local message="$1"
	local j length=${#error_messages[@]}

	for ((j = 0; j < length; j++)); do
		if [ "$message" = "${error_messages[j]}" ]; then
			# We already have this error message; do not add it again.
			return
		fi
	done

	error_messages[length]="$message"
}

# Returns the proper package name based on the system's available package manager.
#
# Arguments:
#   The common name for the package (a fallback name used in case no package manager detected).
#   A space-separate list of package names in the order "brew-package-name apt-package-name dnf-package-name".
get_package_name() {
	local common_name="$1"

	local packages
	read -r -a packages <<<"$2"
	local brew_package="${packages[0]}"
	local apt_package="${packages[1]}"
	local dnf_package="${packages[2]}"

	local package_name

	if [ -n "$brew_path" ]; then
		package_name="$brew_package"
	elif [ -n "$apt_path" ]; then
		package_name="$apt_package"
	elif [ -n "$dnf_path" ]; then
		package_name="$dnf_package"
	else
		package_name="$common_name"
	fi

	printf "%s" "$package_name"
}

# Returns true if we have additional error messages.
has_error_messages() {
	((${#error_messages[@]} > 0))
}

# Returns the path to use as the header file location for the given headers or
# an error status, if the headers could not be found.
#
# Example:
#
#     header_file_location "pspell.h pspell/pspell.h" "$(brew --prefix aspell)"
#
# Arguments:
#   A space-separated list of header file names that may be found in locations like /usr/local or /usr.
#   Additional paths to use when searching for headers.
header_file_location() {
	local header_files
	read -r -a header_files <<<"$1"
	shift 1

	local location header locations=("${@:-}" "/usr/local" "/usr")

	for location in "${locations[@]}"; do
		if [ -z "$location" ]; then
			continue
		fi

		for header in "${header_files[@]}"; do
			if [ -f "${location}/include/${header}" ]; then
				printf "%s" "$(realpath "$location")"
				return
			fi
		done
	done

	return 1
}

# Returns true if we have missing optional packages.
is_missing_optional_packages() {
	((${#missing_optional_packages__keys[@]} > 0))
}

# Returns true if we have missing required commands.
is_missing_required_commands() {
	((${#missing_required_commands__keys[@]} > 0))
}

# Returns true if we have missing required packages.
is_missing_required_packages() {
	((${#missing_required_packages__keys[@]} > 0))
}

# Stores a package name and description to the array of missing optional packages.
#
# Example:
#
#     missing_optional_package "bzip2" "Includes bzip2 compression support"
#
# Arguments:
#   Package name
#   Optional description of the package
missing_optional_package() {
	local package="$1"
	local description="${2:-}"
	local j length=${#missing_optional_packages__keys[@]}

	for ((j = 0; j < length; j++)); do
		if [ "$package" = "${missing_optional_packages__keys[j]}" ]; then
			# The key already exists, so update the value.
			missing_optional_packages__values[j]="$description"
			return
		fi
	done

	missing_optional_packages__keys[length]="$package"
	missing_optional_packages__values[length]="$description"
}

# Stores a command and description to the array of missing required commands.
#
# Example:
#
#     missing_required_command "make" "Build automation tooling"
#
# Arguments:
#   Command
#   Optional description of the command
missing_required_command() {
	local command="$1"
	local description="${2:-}"
	local j length=${#missing_required_commands__keys[@]}

	for ((j = 0; j < length; j++)); do
		if [ "$command" = "${missing_required_commands__keys[j]}" ]; then
			# The key already exists, so update the value.
			missing_required_commands__values[j]="$description"
			return
		fi
	done

	missing_required_commands__keys[length]="$command"
	missing_required_commands__values[length]="$description"
}

# Stores a package name and description to the array of missing required packages.
#
# Example:
#
#     missing_required_package "bzip2" "Includes bzip2 compression support"
#
# Arguments:
#   Package name
#   Optional description of the package
missing_required_package() {
	local package="$1"
	local description="${2:-}"
	local j length=${#missing_required_packages__keys[@]}

	for ((j = 0; j < length; j++)); do
		if [ "$package" = "${missing_required_packages__keys[j]}" ]; then
			# The key already exists, so update the value.
			missing_required_packages__values[j]="$description"
			return
		fi
	done

	missing_required_packages__keys[length]="$package"
	missing_required_packages__values[length]="$description"
}

# Prints a list of additional error messages, if available.
print_error_messages() {
	! has_error_messages && return

	printf "\nAdditional information:\n\n" | asdf_log
	printf "  - %s\n" "${error_messages[@]}" | asdf_log
	printf "\n" | asdf_log
}

# Prints a table of required missing commands, for use in combination with
# print_missing_packages_table() and print_missing_packages_installation().
print_missing_required_commands_table() {
	! is_missing_required_commands && return

	printf "\nThe following required commands are missing:\n\n" | asdf_log

	local j length=${#missing_required_commands__keys[@]}
	for ((j = 0; j < length; j++)); do
		printf "  %-14s%s\n" "${missing_required_commands__keys[$j]}" "${missing_required_commands__values[$j]}" | asdf_log
	done

	printf "\n" | asdf_log
}

# Prints an installation command for either required or optional missing packages.
#
# Example:
#
#     print_missing_packages_install_command "required"
#
# Arguments:
#   Whether to print an installation command for "required" or "optional" packages
print_missing_packages_installation() {
	local state="$1"
	local package_manager="" command=""

	if [ "$state" = "required" ]; then
		! is_missing_required_packages && return
	else
		! is_missing_optional_packages && return
		state="optional"
	fi

	if [ -n "$brew_path" ]; then
		package_manager="Homebrew"
		command="brew install"
	elif [ -n "$apt_path" ]; then
		package_manager="APT"
		command="apt-get install -y"
	elif [ -n "$dnf_path" ]; then
		package_manager="DNF"
		command="dnf install -y"
	fi

	if [ -n "$package_manager" ]; then
		printf "Use %s to install missing %s packages:\n\n" "$package_manager" "$state" | asdf_log

		if [ "$state" = "required" ]; then
			printf "  %s %s\n\n" "$command" "${missing_required_packages__keys[*]}" | asdf_log
		else
			printf "  %s %s\n\n" "$command" "${missing_optional_packages__keys[*]}" | asdf_log
		fi
	fi
}

# Prints a table of either required or optional missing packages.
#
# Example:
#
#     print_missing_packages_table "required"
#
# Arguments:
#   Whether to print "required" or "optional" packages
print_missing_packages_table() {
	local state="$1"

	if [ "$state" = "required" ]; then
		! is_missing_required_packages && return
	else
		! is_missing_optional_packages && return
		state="optional"
	fi

	printf "\nThe following %s packages are missing:\n\n" "$state" | asdf_log

	if [ "$state" = "required" ]; then
		local j length=${#missing_required_packages__keys[@]}
		for ((j = 0; j < length; j++)); do
			printf "  %-22s%s\n" "${missing_required_packages__keys[$j]}" "${missing_required_packages__values[$j]}" | asdf_log
		done
	else
		local j length=${#missing_optional_packages__keys[@]}
		for ((j = 0; j < length; j++)); do
			printf "  %-22s%s\n" "${missing_optional_packages__keys[$j]}" "${missing_optional_packages__values[$j]}" | asdf_log
		done
	fi

	printf "\n" | asdf_log
}

# Returns true if we should build this PHP without support for PEAR.
#
# If PHP_WITHOUT_PEAR is set to anything other than the value "no," this will
# return a success status code indicating that we want to install PHP without
# support for PEAR.
should_install_without_pear() {
	if [ "${PHP_WITHOUT_PEAR:-no}" != "no" ]; then
		return 0
	fi

	return 1
}

# Updates PKG_CONFIG_PATH with the path to the package's .pc files.
#
# This is only necessary for Homebrew packages, since APT and DNF place .pc
# files in common locations.
#
# Arguments:
#   The Homebrew version of the package name.
update_pkg_config_path() {
	if [ -z "$brew_path" ]; then
		# If we don't have Homebrew, do nothing.
		return
	fi

	local package="${1}"
	local brew_prefix

	brew_prefix="$("$brew_path" --prefix "$package" 2>/dev/null || true)"

	if [ -z "$brew_prefix" ] || [ ! -d "$brew_prefix" ]; then
		# If the directory doesn't exist, the package isn't installed; do nothing.
		return
	fi

	export PKG_CONFIG_PATH="${brew_prefix}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
}

# If readline is present, configures the build to use readline;
# otherwise, returns an error status.
use_readline() {
	update_pkg_config_path "readline"

	if ! pkg-config --exists "readline"; then
		return 1
	fi

	add_option "--with-readline=$(pkg-config --variable=prefix "readline")"
}
