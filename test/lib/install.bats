#!/usr/bin/env bats
# shellcheck disable=SC2317

tmp_dir=
log_file=

setup() {
	bats_require_minimum_version 1.5.0

	load '../test_helper/bats-support/load.bash'
	load '../test_helper/bats-assert/load.bash'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	load '../../lib/install.bash'

	tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'tmp_dir')
	log_file="${tmp_dir}/asdf-php-build-test.log"
	truncate -s 0 "$log_file"
}

teardown() {
	if [ -d "$tmp_dir" ]; then
		rm -rf "$tmp_dir"
	fi
}

@test "install_version() returns success status for ref" {
	export ASDF_DOWNLOAD_PATH="/path/to/download"

	expected_output=$(
		cat <<-'EOF'

			PHP version information

			Composer version information

			asdf-php: PHP git_commitish installation was successful!
		EOF
	)

	mkdir() {
		[ "$1" = "-p" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The mkdir command received unexpected arguments: ${*}"
	}

	php_preflight_checks() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The php_preflight_checks command received unexpected arguments: ${*}"
	}

	php_buildconf() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The php_buildconf command received unexpected arguments: ${*}"
	}

	php_configure() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_configure command received unexpected arguments: ${*}"
	}

	php_make_install() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_make_install command received unexpected arguments: ${*}"
	}

	php_composer_install() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_composer_install command received unexpected arguments: ${*}"
	}

	test() {
		[ "$1" = "-x" ] && [ "$2" = "/path/to/install/bin/php" ] && return 0
		fail "The test command received unexpected arguments: ${*}"
	}

	/path/to/install/bin/php() {
		[ "$1" = "--version" ] && printf "PHP version information\n" && return 0
		[ "$1" = "/path/to/install/bin/composer" ] && [ "$2" = "--version" ] && printf "Composer version information\n" && return 0
		fail "The /path/to/install/bin/php command received unexpected arguments: ${*}"
	}

	run -0 install_version "ref" "git_commitish" "/path/to/install"
	assert_output "$expected_output"
}

@test "install_version() prints failure message when a command fails" {
	ASDF_DOWNLOAD_PATH="/path/to/download"

	mkdir() {
		[ "$1" = "-p" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The mkdir command received unexpected arguments: ${*}"
	}

	php_preflight_checks() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The php_preflight_checks command received unexpected arguments: ${*}"
	}

	php_buildconf() {
		fail "The php_buildconf command should not be called for 'version' install types: ${*}"
	}

	php_configure() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_configure command received unexpected arguments: ${*}"
	}

	php_make_install() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_make_install command received unexpected arguments: ${*}"
	}

	php_composer_install() {
		return 1
	}

	run -61 install_version "version" "1.2.3" "/path/to/install"
	assert_output "asdf-php: An error occurred while installing PHP 1.2.3."
}

@test "install_version() prints failure message when the test fails" {
	ASDF_DOWNLOAD_PATH="/path/to/download"

	expected_output=$(
		cat <<-'EOF'
			asdf-php: Expected /path/to/install/bin/php to be executable.
			asdf-php: An error occurred while installing PHP 1.2.3.
		EOF
	)

	mkdir() {
		[ "$1" = "-p" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The mkdir command received unexpected arguments: ${*}"
	}

	php_preflight_checks() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The php_preflight_checks command received unexpected arguments: ${*}"
	}

	php_buildconf() {
		fail "The php_buildconf command should not be called for 'version' install types: ${*}"
	}

	php_configure() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_configure command received unexpected arguments: ${*}"
	}

	php_make_install() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_make_install command received unexpected arguments: ${*}"
	}

	php_composer_install() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The php_composer_install command received unexpected arguments: ${*}"
	}

	test() {
		return 1
	}

	run -71 install_version "version" "1.2.3" "/path/to/install"
	assert_output "$expected_output"
}

@test "php_preflight_checks() returns success status (Linux variant)" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()

	apt_path=
	brew_path=
	dnf_path=
	is_mac_os=no
	EXTRA_LDFLAGS=

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	command() {
		[ "$1" = "-v" ] && [ "$2" = "apt-get" ] && printf "/path/to/apt-get" && return 0
		[ "$1" = "-v" ] && [ "$2" = "brew" ] && printf "/path/to/brew" && return 0
		[ "$1" = "-v" ] && [ "$2" = "dnf" ] && printf "/path/to/dnf" && return 0

		# Succeed on all other commands, so they're not added to the missing packages lists.
		printf "/path/to/cmd"
		return 0
	}

	uname() {
		[ "$1" = "-a" ] && printf "This is a Linux machine" && return 0
		fail "The uname command received unexpected arguments: ${*}"
	}

	php_preflight_checks "/path/to/download"
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	[ "$apt_path" = "/path/to/apt-get" ]
	[ "$brew_path" = "/path/to/brew" ]
	[ "$dnf_path" = "/path/to/dnf" ]
	[ "$is_mac_os" = "no" ]
	[ "$EXTRA_LDFLAGS" = "" ]
}

@test "php_preflight_checks() returns success status (macOS variant)" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()

	apt_path=
	brew_path=
	dnf_path=
	is_mac_os=no
	EXTRA_LDFLAGS=foo

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	command() {
		[ "$1" = "-v" ] && [ "$2" = "apt-get" ] && printf "/path/to/apt-get" && return 0
		[ "$1" = "-v" ] && [ "$2" = "brew" ] && printf "/path/to/brew" && return 0
		[ "$1" = "-v" ] && [ "$2" = "dnf" ] && printf "/path/to/dnf" && return 0

		# Succeed on all other commands, so they're not added to the missing packages lists.
		printf "/path/to/cmd"
		return 0
	}

	uname() {
		[ "$1" = "-a" ] && printf "This is a Darwin machine" && return 0
		fail "The uname command received unexpected arguments: ${*}"
	}

	php_preflight_checks "/path/to/download"
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	[ "$apt_path" = "/path/to/apt-get" ]
	[ "$brew_path" = "/path/to/brew" ]
	[ "$dnf_path" = "/path/to/dnf" ]
	[ "$is_mac_os" = "yes" ]
	[ "$EXTRA_LDFLAGS" = "-Wl,-ld_classic,foo" ]
}

@test "php_preflight_checks() prints failed commands" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()

	expected_output=$(
		cat <<-'EOF'

			The following required commands are missing:

			  autoconf      Produces configure scripts
			  bison         Generates parsers
			  g++           Compiles C++ code
			  gcc           Compiles C code
			  make          Build automation tooling
			  pkg-config    Queries installed libraries
			  re2c          Generates lexers

			Use APT to install missing required packages:

			  apt-get install -y autoconf bison g++ gcc make pkg-config re2c

			asdf-php: Failed to install PHP; see the message above for details.
		EOF
	)

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	command() {
		[ "$1" = "-v" ] && [ "$2" = "apt-get" ] && printf "/path/to/apt-get" && return 0

		# Fail to find any of the other commands tested.
		return 1
	}

	uname() {
		[ "$1" = "-a" ] && printf "This is a Linux machine" && return 0
		fail "The uname command received unexpected arguments: ${*}"
	}

	run ! php_preflight_checks "/path/to/download"
	assert_output "$expected_output"
	run ! is_missing_required_commands
	run ! is_missing_required_packages
}

@test "php_buildconf() returns success status" {
	expected_output=$(
		cat <<-EOF
			asdf-php: Running buildconf to configure the build
		EOF
	)

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	./buildconf() {
		[ "$1" = "--force" ] && return 0
		fail "The buildconf command received unexpected arguments: ${*}"
	}

	run -0 php_buildconf "/path/to/download"
	assert_output "$expected_output"
}

@test "php_buildconf() fails when running buildconf" {
	expected_output=$(
		cat <<-EOF
			asdf-php: Running buildconf to configure the build
			asdf-php: Buildconf failed
		EOF
	)

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	./buildconf() {
		[ "$1" = "--force" ] && return 1
		fail "The buildconf command received unexpected arguments: ${*}"
	}

	run ! php_buildconf "/path/to/download"
	assert_output "$expected_output"
}

@test "php_configure() returns success status" {
	declare -a missing_required_packages__keys=()
	declare -a missing_optional_packages__keys=()
	declare -a configure_options=()

	PKG_CONFIG_PATH="/usr/local:/usr"

	expected_output=$(
		cat <<-EOF
			asdf-php: Configuring the build (this can take a while)...
			asdf-php: To view build progress, tail -f ${log_file}
		EOF
	)

	ensure_log_file() {
		return 0
	}

	id() {
		[ "$1" = "_www" ] && return 0
		fail "The id command received unexpected arguments: ${*}"
	}

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	add_option() {
		return 0
	}

	add_option_header() {
		return 0
	}

	add_option_pkg_config() {
		return 0
	}

	./configure() {
		return 0
	}

	run -0 php_configure "/path/to/download" "/path/to/install" "$log_file"
	assert_output "$expected_output"
}

@test "php_configure() fails when configuring PHP" {
	declare -a missing_required_packages__keys=()
	declare -a missing_optional_packages__keys=()
	declare -a configure_options=()

	PKG_CONFIG_PATH="/usr/local:/usr"

	expected_output=$(
		cat <<-EOF
			asdf-php: Configuring the build (this can take a while)...
			asdf-php: To view build progress, tail -f ${log_file}
			asdf-php: Failed to configure PHP; for details, see ${log_file}
		EOF
	)

	ensure_log_file() {
		return 0
	}

	id() {
		[ "$1" = "_www" ] && return 0
		fail "The id command received unexpected arguments: ${*}"
	}

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	add_option() {
		return 0
	}

	add_option_header() {
		return 0
	}

	add_option_pkg_config() {
		return 0
	}

	./configure() {
		return 1
	}

	run ! php_configure "/path/to/download" "/path/to/install" "$log_file"
	assert_output "$expected_output"
}

@test "php_configure() fails when required packages are missing (DNF variant)" {
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_optional_packages__values=()
	declare -a configure_options=()

	apt_path=
	brew_path=
	dnf_path="/path/to/dnf"

	expected_output=$(
		cat <<-'EOF'

			The following required packages are missing:

			  bzip2-devel           Includes bzip2 compression support
			  libcurl-devel         Includes cURL support
			  freetype-devel        Includes Freetype 2 font support for image processing with GD
			  glibc-devel           Includes character encoding conversion support
			  gmp-devel             Includes GNU multiple precision support
			  libicu-devel          Includes internationalization support with ICU
			  libjpeg-turbo-devel   Includes JPEG support for image processing with GD
			  openldap-devel        Includes LDAP support (and required by libcurl)
			  oniguruma-devel       Enables use of mb_ereg* functions
			  openssl-devel         Includes OpenSSL support
			  libpng-devel          Includes PNG support for image processing with GD
			  libedit-devel         Includes Readline support
			  libsodium-devel       Includes Sodium cryptographic support
			  libsqlite3x-devel     Includes SQLite3 support
			  libxml2-devel         Includes XML and DOM parsing support
			  libzip-devel          Includes Zip archive support
			  zlib-devel            Includes zlib compression support

			Use DNF to install missing required packages:

			  dnf install -y bzip2-devel libcurl-devel freetype-devel glibc-devel gmp-devel libicu-devel libjpeg-turbo-devel openldap-devel oniguruma-devel openssl-devel libpng-devel libedit-devel libsodium-devel libsqlite3x-devel libxml2-devel libzip-devel zlib-devel

			asdf-php: Failed to install PHP; see the message above for details.
		EOF
	)

	ensure_log_file() {
		return 0
	}

	id() {
		[ "$1" = "_www" ] && return 0
		fail "The id command received unexpected arguments: ${*}"
	}

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	add_option() {
		return 0
	}

	header_file_location() {
		return 1
	}

	update_pkg_config_path() {
		return 0
	}

	pkg-config() {
		return 1
	}

	run ! php_configure "/path/to/download" "/path/to/install" "$log_file"
	assert_output "$expected_output"
}

@test "php_configure() succeeds when optional packages are missing (APT variant)" {
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_optional_packages__values=()
	declare -a configure_options=()

	apt_path="/path/to/apt-get"
	brew_path=
	dnf_path=
	PKG_CONFIG_PATH="/usr/local:/usr"

	expected_output=$(
		cat <<-EOF

			The following optional packages are missing:

			  libargon2-dev         Enables use of Argon2 password hashing
			  libavif-dev           Includes AVIF support for image processing with GD
			  libenchant-2-dev      Includes Enchant spellcheck support
			  libffi-dev            Includes foreign function interface support
			  libgdbm-dev           Includes GNU dbm support
			  libkrb5-dev           Includes Kerberos support in openssl_*
			  unixodbc-dev          Includes ODBC support
			  libpq-dev             Enables use of PostgreSQL
			  libpspell-dev         Includes Pspell spellcheck support
			  libsnmp-dev           Includes SNMP support
			  libtidy-dev           Includes Tidy support
			  libwebp-dev           Includes WEBP support for image processing with GD
			  libxpm-dev            Includes XPM support for image processing with GD
			  libxslt1-dev          Includes XSLT support

			Use APT to install missing optional packages:

			  apt-get install -y libargon2-dev libavif-dev libenchant-2-dev libffi-dev libgdbm-dev libkrb5-dev unixodbc-dev libpq-dev libpspell-dev libsnmp-dev libtidy-dev libwebp-dev libxpm-dev libxslt1-dev

			asdf-php: Missing some optional packages; see above.

			  Use Ctrl-C to cancel the build and install these, if you wish to include them.

			asdf-php: Configuring the build (this can take a while)...
			asdf-php: To view build progress, tail -f ${log_file}
		EOF
	)

	ensure_log_file() {
		return 0
	}

	id() {
		[ "$1" = "_www" ] && return 0
		fail "The id command received unexpected arguments: ${*}"
	}

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	add_option() {
		return 0
	}

	header_file_location() {
		return 1
	}

	update_pkg_config_path() {
		return 0
	}

	pkg-config() {
		return 1
	}

	is_missing_required_packages() {
		# We want this to return an error status, so we display the missing
		# optional packages message, for testing purposes.
		return 1
	}

	./configure() {
		return 0
	}

	# Add this for coverage reporting.
	# shellcheck disable=SC2030
	export PHP_WITHOUT_PEAR="yes"

	run -0 php_configure "/path/to/download" "/path/to/install" "$log_file"
	assert_output "$expected_output"
}

@test "php_make_install() returns success status" {
	export ASDF_CONCURRENCY=42
	make_path="/path/to/make"
	gcc_path="/path/to/gcc"
	gxx_path="/path/to/g++"

	expected_output=$(
		cat <<-EOF
			asdf-php: Building PHP (this can take a while)...
			asdf-php: Installing PHP to /path/to/install
		EOF
	)

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	mkdir() {
		[ "$1" = "-p" ] && [ "$2" = "/path/to/install/etc/php.d" ] && return 0
		fail "The mkdir command received unexpected arguments: ${*}"
	}

	cp() {
		[ "$1" = "/path/to/download/php.ini-development" ] && [ "$2" = "/path/to/install/etc/php.ini" ] && return 0
		fail "The cp command received unexpected arguments: ${*}"
	}

	/path/to/make() {
		[ "$1" = "CC=/path/to/gcc" ] && [ "$2" = "CXX=/path/to/g++" ] && [ "$3" = "EXTRA_CFLAGS=-w" ] && [ "$4" = "EXTRA_LDFLAGS=" ] && [ "$5" = "-j42" ] && [ -z "${6:-}" ] && return 0
		[ "$1" = "CC=/path/to/gcc" ] && [ "$2" = "CXX=/path/to/g++" ] && [ "$3" = "EXTRA_CFLAGS=-w" ] && [ "$4" = "EXTRA_LDFLAGS=" ] && [ "$5" = "-j42" ] && [ "$6" = "install" ] && return 0
		fail "The /path/to/make command received unexpected arguments: ${*}"
	}

	run -0 php_make_install "/path/to/download" "/path/to/install" "$log_file"
	assert_output "$expected_output"
}

@test "php_make_install() fails when building PHP" {
	ASDF_CONCURRENCY=42
	make_path="/path/to/make"
	gcc_path="/path/to/gcc"
	gxx_path="/path/to/g++"

	expected_output=$(
		cat <<-EOF
			asdf-php: Building PHP (this can take a while)...
			asdf-php: Failed to build PHP; for details, see ${log_file}
		EOF
	)

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	/path/to/make() {
		[ "$1" = "CC=/path/to/gcc" ] && [ "$2" = "CXX=/path/to/g++" ] && [ "$3" = "-j42" ] && [ -z "${4:-}" ] && return 1
		fail "The /path/to/make command received unexpected arguments: ${*}"
	}

	run ! php_make_install "/path/to/download" "/path/to/install" "$log_file"
	assert_output "$expected_output"
}

@test "php_make_install() fails when installing PHP" {
	ASDF_CONCURRENCY=42
	make_path="/path/to/make"
	gcc_path="/path/to/gcc"
	gxx_path="/path/to/g++"

	expected_output=$(
		cat <<-EOF
			asdf-php: Building PHP (this can take a while)...
			asdf-php: Installing PHP to /path/to/install
			asdf-php: Failed to install PHP; for details, see ${log_file}
		EOF
	)

	cd() {
		[ "$1" = "/path/to/download" ] && return 0
		fail "The cd command received unexpected arguments: ${*}"
	}

	/path/to/make() {
		[ "$1" = "CC=/path/to/gcc" ] && [ "$2" = "CXX=/path/to/g++" ] && [ "$3" = "EXTRA_CFLAGS=-w" ] && [ "$4" = "EXTRA_LDFLAGS=" ] && [ "$5" = "-j42" ] && [ -z "${6:-}" ] && return 0
		[ "$1" = "CC=/path/to/gcc" ] && [ "$2" = "CXX=/path/to/g++" ] && [ "$3" = "EXTRA_CFLAGS=-w" ] && [ "$4" = "EXTRA_LDFLAGS=" ] && [ "$5" = "-j42" ] && [ "$6" = "install" ] && return 1
		fail "The /path/to/make command received unexpected arguments: ${*}"
	}

	run ! php_make_install "/path/to/download" "/path/to/install" "$log_file"
	assert_output "$expected_output"
}

@test "php_composer_install() returns success status" {
	composer_download() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The composer_download command received unexpected arguments: ${*}"
	}

	composer_install() {
		[ "$1" = "/path/to/download" ] && [ "$2" = "/path/to/install" ] && return 0
		fail "The composer_install command received unexpected arguments: ${*}"
	}

	run -0 php_composer_install "/path/to/download" "/path/to/install"
	assert_output "asdf-php: Installing Composer to /path/to/install"
}

@test "php_composer_install() fails when composer_download fails" {
	expected_output=$(
		cat <<-EOF
			asdf-php: Installing Composer to /path/to/install
			asdf-php: Failed to download Composer
		EOF
	)

	composer_download() {
		return 1
	}

	run ! php_composer_install "/path/to/download" "/path/to/install"
	assert_output "$expected_output"
}

@test "php_composer_install() fails when composer_install fails" {
	expected_output=$(
		cat <<-EOF
			asdf-php: Installing Composer to /path/to/install
			asdf-php: Failed to install Composer
		EOF
	)

	composer_download() {
		return 0
	}

	composer_install() {
		return 1
	}

	run ! php_composer_install "/path/to/download" "/path/to/install"
	assert_output "$expected_output"
}

@test "add_option() updates configure_options array" {
	declare -a configure_options=()

	((${#configure_options[@]} == 0))

	add_option "--foo"
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--foo" ]

	add_option "--bar"
	((${#configure_options[@]} == 2))
	[ "${configure_options[1]}" = "--bar" ]
}

@test "add_option_header() succeeds (Homebrew variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	brew_path="/path/to/brew"

	/path/to/brew() {
		[ "$1" = "--prefix" ] && [ "$2" = "bzip2" ] && printf "/path/to/brew/bzip2" && return 0
		fail "The /path/to/brew command received unexpected arguments: ${*}"
	}

	header_file_location() {
		[ "$1" = "bzlib.h" ] && [ "$2" = "/path/to/brew/bzip2" ] && printf "/headers/location" && return 0
		fail "The header_file_location command received unexpected arguments: ${*}"
	}

	((${#configure_options[@]} == 0))

	add_option_header "bzip2" "bzip2 libbz2-dev bzip2-devel" "bzlib.h" "--with-bz2=" "Includes bzip2 compression support" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-bz2=/headers/location" ]
}

@test "add_option_header() fails for required package (Homebrew variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	brew_path="/path/to/brew"

	/path/to/brew() {
		[ "$1" = "--prefix" ] && [ "$2" = "bzip2" ] && printf "/path/to/brew/bzip2" && return 0
		fail "The /path/to/brew command received unexpected arguments: ${*}"
	}

	header_file_location() {
		return 1
	}

	((${#configure_options[@]} == 0))

	add_option_header "bzip2" "bzip2 libbz2-dev bzip2-devel" "bzlib.h" "--with-bz2" "Includes bzip2 compression support" "required"
	run ! is_missing_optional_packages
	run -0 is_missing_required_packages
	((${#configure_options[@]} == 0))
	((${#missing_required_packages__keys[@]} == 1))
	[ "${missing_required_packages__keys[0]}" = "bzip2" ]
}

@test "add_option_header() fails for required package (APT variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	apt_path="/path/to/apt-get"

	header_file_location() {
		return 1
	}

	((${#configure_options[@]} == 0))

	add_option_header "bzip2" "bzip2 libbz2-dev bzip2-devel" "bzlib.h" "--with-bz2" "Includes bzip2 compression support" "required"
	run ! is_missing_optional_packages
	run -0 is_missing_required_packages
	((${#configure_options[@]} == 0))
	((${#missing_required_packages__keys[@]} == 1))
	[ "${missing_required_packages__keys[0]}" = "libbz2-dev" ]
}

@test "add_option_header() fails for optional package (DNF variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	dnf_path="/path/to/dnf"

	header_file_location() {
		return 1
	}

	((${#configure_options[@]} == 0))

	add_option_header "bzip2" "bzip2 libbz2-dev bzip2-devel" "bzlib.h" "--with-bz2" "Includes bzip2 compression support" "optional"
	run -0 is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 0))
	((${#missing_optional_packages__keys[@]} == 1))
	[ "${missing_optional_packages__keys[0]}" = "bzip2-devel" ]
}

@test "add_option_header() fails for optional package (No package manager variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()

	header_file_location() {
		return 1
	}

	((${#configure_options[@]} == 0))

	add_option_header "bzip2" "bzip2 libbz2-dev bzip2-devel" "bzlib.h" "--with-bz2" "Includes bzip2 compression support" "optional"
	run -0 is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 0))
	((${#missing_optional_packages__keys[@]} == 1))
	[ "${missing_optional_packages__keys[0]}" = "bzip2" ]
}

@test "add_option_header() succeeds using --with-iconv and /usr search prefix" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	apt_path="/path/to/apt-get"

	header_file_location() {
		[ "$1" = "iconv.h" ] && [ "$2" = "" ] && printf "/usr" && return 0
		fail "The header_file_location command received unexpected arguments: ${*}"
	}

	((${#configure_options[@]} == 0))

	add_option_header "iconv" "libiconv libc6-dev glibc-devel" "iconv.h" "--with-iconv=" "Testing description" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-iconv" ]
}

@test "add_option_header() succeeds using --with-iconv and /usr/local search prefix" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	apt_path="/path/to/apt-get"

	header_file_location() {
		[ "$1" = "iconv.h" ] && [ "$2" = "" ] && printf "/usr/local" && return 0
		fail "The header_file_location command received unexpected arguments: ${*}"
	}

	((${#configure_options[@]} == 0))

	add_option_header "iconv" "libiconv libc6-dev glibc-devel" "iconv.h" "--with-iconv=" "Testing description" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-iconv" ]
}

@test "add_option_header() succeeds using --with-iconv and /opt/homebrew/opt/libiconv search prefix" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	apt_path="/path/to/apt-get"

	header_file_location() {
		[ "$1" = "iconv.h" ] && [ "$2" = "" ] && printf "/opt/homebrew/opt/libiconv" && return 0
		fail "The header_file_location command received unexpected arguments: ${*}"
	}

	((${#configure_options[@]} == 0))

	add_option_header "iconv" "libiconv libc6-dev glibc-devel" "iconv.h" "--with-iconv=" "Testing description" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-iconv=/opt/homebrew/opt/libiconv" ]
}

@test "add_option_header() succeeds using --with-ldap and /usr search prefix" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	apt_path="/path/to/apt-get"

	header_file_location() {
		[ "$1" = "ldap.h" ] && [ "$2" = "" ] && printf "/usr" && return 0
		fail "The header_file_location command received unexpected arguments: ${*}"
	}

	update_pkg_config_path() {
		[ "$1" = "libldap2-dev" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	((${#configure_options[@]} == 0))

	add_option_header "ldap" "openldap libldap2-dev openldap-devel" "ldap.h" "--with-ldap=" "Testing description" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-ldap" ]
}

@test "add_option_header() succeeds using --with-ldap and /usr/local search prefix" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	dnf_path="/path/to/dnf"

	header_file_location() {
		[ "$1" = "ldap.h" ] && [ "$2" = "" ] && printf "/usr" && return 0
		fail "The header_file_location command received unexpected arguments: ${*}"
	}

	update_pkg_config_path() {
		[ "$1" = "openldap-devel" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	((${#configure_options[@]} == 0))

	add_option_header "ldap" "openldap libldap2-dev openldap-devel" "ldap.h" "--with-ldap=" "Testing description" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-ldap" ]
}

@test "add_option_header() succeeds using --with-ldap and /opt/homebrew/opt/openldap search prefix" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	brew_path="/path/to/brew"

	header_file_location() {
		[ "$1" = "ldap.h" ] && [ "$2" = "" ] && printf "/opt/homebrew/opt/openldap" && return 0
		fail "The header_file_location command received unexpected arguments: ${*}"
	}

	update_pkg_config_path() {
		[ "$1" = "openldap" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	((${#configure_options[@]} == 0))

	add_option_header "ldap" "openldap libldap2-dev openldap-devel" "ldap.h" "--with-ldap=" "Testing description" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-ldap=/opt/homebrew/opt/openldap" ]
}

@test "add_option_php_fpm() detects _www user" {
	id() {
		[ "$1" = "_www" ] && return 0
		fail "The id command received unexpected arguments: ${*}"
	}

	declare -a configure_options=()

	add_option_php_fpm
	((${#configure_options[@]} == 3))
	[ "${configure_options[0]}" = "--enable-fpm" ]
	[ "${configure_options[1]}" = "--with-fpm-user=_www" ]
	[ "${configure_options[2]}" = "--with-fpm-group=_www" ]
}

@test "add_option_php_fpm() detects www-data user" {
	id() {
		[ "$1" = "www-data" ] && return 0
		fail "The id command received unexpected arguments: ${*}"
	}

	declare -a configure_options=()

	add_option_php_fpm
	((${#configure_options[@]} == 3))
	[ "${configure_options[0]}" = "--enable-fpm" ]
	[ "${configure_options[1]}" = "--with-fpm-user=www-data" ]
	[ "${configure_options[2]}" = "--with-fpm-group=www-data" ]
}

@test "add_option_php_fpm() defaults to nobody user" {
	id() {
		return 1
	}

	declare -a configure_options=()

	add_option_php_fpm
	((${#configure_options[@]} == 3))
	[ "${configure_options[0]}" = "--enable-fpm" ]
	[ "${configure_options[1]}" = "--with-fpm-user=nobody" ]
	[ "${configure_options[2]}" = "--with-fpm-group=nobody" ]
}

@test "add_option_pkg_config() succeeds" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()

	update_pkg_config_path() {
		[ "$1" = "curl" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	pkg-config() {
		[ "$1" = "--exists" ] && [ "$2" = "libcurl" ] && return 0
		[ "$1" = "--variable=prefix" ] && [ "$2" = "libcurl" ] && printf "/path/to/libcurl/prefix" && return 0
		fail "The pkg-config command received unexpected arguments: ${*}"
	}

	add_option_pkg_config "curl" "curl libcurl4-openssl-dev libcurl-devel" "libcurl" "--with-curl" "Includes cURL support" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-curl" ]
}

@test "add_option_pkg_config() succeeds using prefix and multiple options" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()

	update_pkg_config_path() {
		[ "$1" = "gmp" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	pkg-config() {
		[ "$1" = "--exists" ] && [ "$2" = "gmp" ] && return 0
		[ "$1" = "--variable=prefix" ] && [ "$2" = "gmp" ] && printf "/path/to/gmp/prefix" && return 0
		fail "The pkg-config command received unexpected arguments: ${*}"
	}

	add_option_pkg_config "gmp" "foo bar baz" "gmp" "--foo= --bar --with-gmp= --with-something=unixODBC," "Testing" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 4))
	[ "${configure_options[0]}" = "--foo=/path/to/gmp/prefix" ]
	[ "${configure_options[1]}" = "--bar" ]
	[ "${configure_options[2]}" = "--with-gmp=/path/to/gmp/prefix" ]
	[ "${configure_options[3]}" = "--with-something=unixODBC,/path/to/gmp/prefix" ]
}

@test "add_option_pkg_config() fails for required package (Homebrew variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	brew_path="/path/to/brew"

	update_pkg_config_path() {
		[ "$1" = "curl" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	pkg-config() {
		[ "$1" = "--exists" ] && [ "$2" = "libcurl" ] && return 1
		fail "The pkg-config command received unexpected arguments: ${*}"
	}

	add_option_pkg_config "curl" "curl libcurl4-openssl-dev libcurl-devel" "libcurl" "--with-curl" "Includes cURL support" "required"
	run ! is_missing_optional_packages
	run -0 is_missing_required_packages
	((${#configure_options[@]} == 0))
	((${#missing_required_packages__keys[@]} == 1))
	[ "${missing_required_packages__keys[0]}" = "curl" ]
}

@test "add_option_pkg_config() fails for required package (APT variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	apt_path="/path/to/apt-get"

	update_pkg_config_path() {
		[ "$1" = "libcurl4-openssl-dev" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	pkg-config() {
		[ "$1" = "--exists" ] && [ "$2" = "libcurl" ] && return 1
		fail "The pkg-config command received unexpected arguments: ${*}"
	}

	add_option_pkg_config "curl" "curl libcurl4-openssl-dev libcurl-devel" "libcurl" "--with-curl" "Includes cURL support" "required"
	run ! is_missing_optional_packages
	run -0 is_missing_required_packages
	((${#configure_options[@]} == 0))
	((${#missing_required_packages__keys[@]} == 1))
	[ "${missing_required_packages__keys[0]}" = "libcurl4-openssl-dev" ]
}

@test "add_option_pkg_config() fails for optional package (DNF variant)" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()
	dnf_path="/path/to/dnf"

	update_pkg_config_path() {
		[ "$1" = "enchant2-devel" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	pkg-config() {
		[ "$1" = "--exists" ] && [ "$2" = "enchant-2" ] && return 1
		fail "The pkg-config command received unexpected arguments: ${*}"
	}

	add_option_pkg_config "enchant" "enchant libenchant-2-dev enchant2-devel" "enchant-2" "--with-enchant" "Includes Enchant spell-checking support" "optional"
	run -0 is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 0))
	((${#missing_optional_packages__keys[@]} == 1))
	[ "${missing_optional_packages__keys[0]}" = "enchant2-devel" ]
}

@test "add_option_pkg_config() when readline is installed" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()

	update_pkg_config_path() {
		[ "$1" = "readline" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	pkg-config() {
		[ "$1" = "--exists" ] && [ "$2" = "readline" ] && return 0
		[ "$1" = "--variable=prefix" ] && [ "$2" = "readline" ] && printf "/path/to/readline/prefix" && return 0
		fail "The pkg-config command received unexpected arguments: ${*}"
	}

	add_option_pkg_config "readline" "libedit libedit-dev libedit-devel" "libedit" "--with-libedit" "This is a test" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-readline=/path/to/readline/prefix" ]
}

@test "add_option_pkg_config() when readline is not installed" {
	declare -a configure_options=()
	declare -a missing_optional_packages__keys=()
	declare -a missing_required_packages__keys=()

	update_pkg_config_path() {
		[ "$1" = "readline" ] && return 0
		[ "$1" = "libedit" ] && return 0
		fail "The update_pkg_config_path command received unexpected arguments: ${*}"
	}

	pkg-config() {
		[ "$1" = "--exists" ] && [ "$2" = "readline" ] && return 1
		[ "$1" = "--exists" ] && [ "$2" = "libedit" ] && return 0
		[ "$1" = "--variable=prefix" ] && [ "$2" = "libedit" ] && printf "/path/to/libedit/prefix" && return 0
		fail "The pkg-config command received unexpected arguments: ${*}"
	}

	add_option_pkg_config "readline" "libedit libedit-dev libedit-devel" "libedit" "--with-libedit" "This is a test" "required"
	run ! is_missing_optional_packages
	run ! is_missing_required_packages
	((${#configure_options[@]} == 1))
	[ "${configure_options[0]}" = "--with-libedit" ]
}

@test "check_autoconf() finds autoconf" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()

	command() {
		[ "$1" = "-v" ] && [ "$2" = "autoconf" ] && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_autoconf
	run ! is_missing_required_commands
	run ! is_missing_required_packages
}

@test "check_autoconf() fails to find autoconf" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_commands__values=()
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()

	command() {
		return 1
	}

	check_autoconf
	is_missing_required_commands
	is_missing_required_packages
}

@test "check_bison() finds bison" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()

	command() {
		[ "$1" = "-v" ] && [ "$2" = "bison" ] && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_bison
	run ! is_missing_required_commands
	run ! is_missing_required_packages
}

@test "check_bison() fails to find bison" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_commands__values=()
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()

	command() {
		return 1
	}

	check_bison
	is_missing_required_commands
	is_missing_required_packages
}

@test "check_g++() finds g++-13" {
	skip "Excluding alternate versions of g++, for now"

	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gxx_path=

	command() {
		[ "$1" = "-v" ] && [ "$2" = "g++-13" ] && printf "/path/to/g++-13" && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_g++
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	run ! has_error_messages
	[ "$gxx_path" = "/path/to/g++-13" ]
}

@test "check_g++() finds g++" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gxx_path=

	command() {
		[ "$1" = "-v" ] && [ "$2" = "g++" ] && printf "/path/to/g++" && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_g++
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	run ! has_error_messages
	[ "$gxx_path" = "/path/to/g++" ]
}

@test "check_g++() fails to find g++" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gxx_path=

	command() {
		return 1
	}

	check_g++
	is_missing_required_commands
	is_missing_required_packages
	run ! has_error_messages
	[ "$gxx_path" = "" ]
	[ "${missing_required_packages__keys[0]}" = "g++" ]
}

@test "check_g++() fails to find g++ when using Homebrew" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gxx_path=
	brew_path="/path/to/brew"

	command() {
		return 1
	}

	check_g++
	is_missing_required_commands
	is_missing_required_packages
	run ! has_error_messages
	[ "$gxx_path" = "" ]
	[ "${missing_required_packages__keys[0]}" = "gcc" ]
}

@test "check_g++() fails to find g++ when on macOS" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gxx_path=
	is_mac_os=yes

	command() {
		return 1
	}

	check_g++
	is_missing_required_commands
	is_missing_required_packages
	has_error_messages
	[ "$gxx_path" = "" ]
	[ "${missing_required_packages__keys[0]}" = "g++" ]
	[ "${error_messages[0]}" = "On macOS, you may need to install the Command Line Tools for Xcode." ]
}

@test "check_gcc() finds gcc-13" {
	skip "Excluding alternate versions of gcc, for now"

	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gcc_path=

	command() {
		[ "$1" = "-v" ] && [ "$2" = "gcc-13" ] && printf "/path/to/gcc-13" && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_gcc
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	run ! has_error_messages
	[ "$gcc_path" = "/path/to/gcc-13" ]
}

@test "check_gcc() finds gcc" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gcc_path=

	command() {
		[ "$1" = "-v" ] && [ "$2" = "gcc" ] && printf "/path/to/gcc" && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_gcc
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	run ! has_error_messages
	[ "$gcc_path" = "/path/to/gcc" ]
}

@test "check_gcc() fails to find gcc" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gcc_path=

	command() {
		return 1
	}

	check_gcc
	is_missing_required_commands
	is_missing_required_packages
	run ! has_error_messages
	[ "$gcc_path" = "" ]
	[ "${missing_required_packages__keys[0]}" = "gcc" ]
}

@test "check_gcc() fails to find gcc when on macOS" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	gcc_path=
	is_mac_os=yes

	command() {
		return 1
	}

	check_gcc
	is_missing_required_commands
	is_missing_required_packages
	has_error_messages
	[ "$gcc_path" = "" ]
	[ "${missing_required_packages__keys[0]}" = "gcc" ]
	[ "${error_messages[0]}" = "On macOS, you may need to install the Command Line Tools for Xcode." ]
}

@test "check_make() finds gmake" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	make_path=

	command() {
		[ "$1" = "-v" ] && [ "$2" = "gmake" ] && printf "/path/to/gmake" && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_make
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	run ! has_error_messages
	[ "$make_path" = "/path/to/gmake" ]
}

@test "check_make() finds make" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	make_path=

	command() {
		[ "$1" = "-v" ] && [ "$2" = "make" ] && printf "/path/to/make" && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_make
	run ! is_missing_required_commands
	run ! is_missing_required_packages
	run ! has_error_messages
	[ "$make_path" = "/path/to/make" ]
}

@test "check_make() fails to find make" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	make_path=

	command() {
		return 1
	}

	check_make
	is_missing_required_commands
	is_missing_required_packages
	run ! has_error_messages
	[ "$make_path" = "" ]
	[ "${missing_required_packages__keys[0]}" = "make" ]
}

@test "check_make() fails to find make when on macOS" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()
	declare -a error_messages=()
	make_path=
	is_mac_os=yes

	command() {
		return 1
	}

	check_make
	is_missing_required_commands
	is_missing_required_packages
	has_error_messages
	[ "$make_path" = "" ]
	[ "${missing_required_packages__keys[0]}" = "make" ]
	[ "${error_messages[0]}" = "On macOS, you may need to install the Command Line Tools for Xcode." ]
}

@test "check_pkg_config() finds pkg-config" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()

	command() {
		[ "$1" = "-v" ] && [ "$2" = "pkg-config" ] && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_pkg_config
	run ! is_missing_required_commands
	run ! is_missing_required_packages
}

@test "check_pkg_config() fails to find pkg-config" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_commands__values=()
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()

	command() {
		return 1
	}

	check_pkg_config
	is_missing_required_commands
	is_missing_required_packages
}

@test "check_re2c() finds re2c" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_packages__keys=()

	command() {
		[ "$1" = "-v" ] && [ "$2" = "re2c" ] && return 0
		fail "The 'command' command received unexpected arguments: ${*}"
	}

	check_re2c
	run ! is_missing_required_commands
	run ! is_missing_required_packages
}

@test "check_re2c() fails to find re2c" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_commands__values=()
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()

	command() {
		return 1
	}

	check_re2c
	is_missing_required_commands
	is_missing_required_packages
}

@test "error_message() updates error_messages array" {
	declare -a error_messages=()

	((${#error_messages[@]} == 0))

	error_message "An error message"
	((${#error_messages[@]} == 1))
	[ "${error_messages[0]}" = "An error message" ]

	# We should not be able to add the same message twice.
	error_message "An error message"
	((${#error_messages[@]} == 1))

	# But we should be able to add other error messages.
	error_message "Another error message"
	((${#error_messages[@]} == 2))
	[ "${error_messages[1]}" = "Another error message" ]
}

@test "get_package_name() returns common name" {
	run -0 get_package_name "common" "brew apt dnf"
	assert_output "common"
}

@test "get_package_name() returns brew name" {
	brew_path="/path/to/brew"

	run -0 get_package_name "common" "brew apt dnf"
	assert_output "brew"
}

@test "get_package_name() returns apt name" {
	apt_path="/path/to/apt-get"

	run -0 get_package_name "common" "brew apt dnf"
	assert_output "apt"
}

@test "get_package_name() returns dnf name" {
	dnf_path="/path/to/dnf"

	run -0 get_package_name "common" "brew apt dnf"
	assert_output "dnf"
}

@test "has_error_messages() returns false when there are no error messages" {
	declare -a error_messages=()
	run ! has_error_messages
}

@test "has_error_messages() returns true when there are error messages" {
	declare -a error_messages=()
	error_message "An error message"
	has_error_messages
}

@test "header_file_location() returns error status when header file is not found" {
	run ! header_file_location "foo.h foo/foo.h"
	assert_output ""
}

@test "header_file_location() returns file path when header file found" {
	run -0 header_file_location "foo.h" "$DIR/../fixtures"
	assert_output "$(realpath "$DIR/../fixtures")"
}

@test "header_file_location() returns file path when header file found using multiple header files" {
	run -0 header_file_location "bar.h bar/bar.h" "$DIR/../fixtures"
	assert_output "$(realpath "$DIR/../fixtures")"
}

@test "missing_optional_package() updates missing_optional_packages__* arrays" {
	declare -a missing_optional_packages__keys=()
	declare -a missing_optional_packages__values=()

	((${#missing_optional_packages__keys[@]} == 0))
	((${#missing_optional_packages__values[@]} == 0))

	missing_optional_package "pkg1" "Description for package 1"
	((${#missing_optional_packages__keys[@]} == 1))
	((${#missing_optional_packages__values[@]} == 1))
	[ "${missing_optional_packages__keys[0]}" = "pkg1" ]
	[ "${missing_optional_packages__values[0]}" = "Description for package 1" ]

	# We can update descriptions for packages already in the array.
	missing_optional_package "pkg1" "Updated description for package 1"
	((${#missing_optional_packages__keys[@]} == 1))
	((${#missing_optional_packages__values[@]} == 1))
	[ "${missing_optional_packages__keys[0]}" = "pkg1" ]
	[ "${missing_optional_packages__values[0]}" = "Updated description for package 1" ]

	# We can add other packages, omitting the description, if we like.
	missing_optional_package "pkg2"
	((${#missing_optional_packages__keys[@]} == 2))
	((${#missing_optional_packages__values[@]} == 2))
	[ "${missing_optional_packages__keys[1]}" = "pkg2" ]
	[ "${missing_optional_packages__values[1]}" = "" ]
}

@test "is_missing_optional_packages() returns false when there are no missing optional packages" {
	declare -a missing_optional_packages__keys=()
	run ! is_missing_optional_packages
}

@test "is_missing_optional_packages() returns true when there are missing optional packages" {
	declare -a missing_optional_packages__keys=()
	declare -a missing_optional_packages__values=()
	missing_optional_package "pkg1" "Description for package 1"
	is_missing_optional_packages
}

@test "missing_required_command() updates missing_required_commands__* arrays" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_commands__values=()

	((${#missing_required_commands__keys[@]} == 0))
	((${#missing_required_commands__values[@]} == 0))

	missing_required_command "cmd1" "Description for command 1"
	((${#missing_required_commands__keys[@]} == 1))
	((${#missing_required_commands__values[@]} == 1))
	[ "${missing_required_commands__keys[0]}" = "cmd1" ]
	[ "${missing_required_commands__values[0]}" = "Description for command 1" ]

	# We can update descriptions for commands already in the array.
	missing_required_command "cmd1" "Updated description for command 1"
	((${#missing_required_commands__keys[@]} == 1))
	((${#missing_required_commands__values[@]} == 1))
	[ "${missing_required_commands__keys[0]}" = "cmd1" ]
	[ "${missing_required_commands__values[0]}" = "Updated description for command 1" ]

	# We can add other commands, omitting the description, if we like.
	missing_required_command "cmd2"
	((${#missing_required_commands__keys[@]} == 2))
	((${#missing_required_commands__values[@]} == 2))
	[ "${missing_required_commands__keys[1]}" = "cmd2" ]
	[ "${missing_required_commands__values[1]}" = "" ]
}

@test "is_missing_required_commands() returns false when there are no missing required commands" {
	declare -a missing_required_commands__keys=()
	run ! is_missing_required_commands
}

@test "is_missing_required_commands() returns true when there are missing required commands" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_commands__values=()
	missing_required_command "cmd1" "Description for command 1"
	is_missing_required_commands
}

@test "missing_required_package() updates missing_required_packages__* arrays" {
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()

	((${#missing_required_packages__keys[@]} == 0))
	((${#missing_required_packages__values[@]} == 0))

	missing_required_package "pkg1" "Description for package 1"
	((${#missing_required_packages__keys[@]} == 1))
	((${#missing_required_packages__values[@]} == 1))
	[ "${missing_required_packages__keys[0]}" = "pkg1" ]
	[ "${missing_required_packages__values[0]}" = "Description for package 1" ]

	# We can update descriptions for packages already in the array.
	missing_required_package "pkg1" "Updated description for package 1"
	((${#missing_required_packages__keys[@]} == 1))
	((${#missing_required_packages__values[@]} == 1))
	[ "${missing_required_packages__keys[0]}" = "pkg1" ]
	[ "${missing_required_packages__values[0]}" = "Updated description for package 1" ]

	# We can add other packages, omitting the description, if we like.
	missing_required_package "pkg2"
	((${#missing_required_packages__keys[@]} == 2))
	((${#missing_required_packages__values[@]} == 2))
	[ "${missing_required_packages__keys[1]}" = "pkg2" ]
	[ "${missing_required_packages__values[1]}" = "" ]
}

@test "is_missing_required_packages() returns false when there are no missing required packages" {
	declare -a missing_required_packages__keys=()
	run ! is_missing_required_packages
}

@test "is_missing_required_packages() returns true when there are missing required packages" {
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()
	missing_required_package "pkg1" "Description for package 1"
	is_missing_required_packages
}

@test "print_error_messages() does not print anything when there are no error messages" {
	declare -a error_messages=()
	run print_error_messages
	assert_output ""
}

@test "print_error_messages() prints a list of error messages" {
	declare -a error_messages=()

	expected_output=$(
		cat <<-'EOF'

			Additional information:

			  - An error message
			  - Another error message
		EOF
	)

	error_message "An error message"
	error_message "Another error message"

	run print_error_messages
	assert_output "$expected_output"
}

@test "print_missing_required_commands_table() does not print anything when there are no missing required commands" {
	declare -a missing_required_commands__keys=()
	run print_missing_required_commands_table
	assert_output ""
}

@test "print_missing_required_commands_table()" {
	declare -a missing_required_commands__keys=()
	declare -a missing_required_commands__values=()

	expected_output=$(
		cat <<-'EOF'

			The following required commands are missing:

			  cmd1          Description for command 1
			  cmd2          Description for command 2
			  cmd3          Description for command 3
		EOF
	)

	missing_required_command "cmd1" "Description for command 1"
	missing_required_command "cmd2" "Description for command 2"
	missing_required_command "cmd3" "Description for command 3"

	run print_missing_required_commands_table
	assert_output "$expected_output"
}

@test "print_missing_packages_installation(required) does not print anything when there are no missing required packages" {
	declare -a missing_required_packages__keys=()
	run print_missing_packages_installation "required"
	assert_output ""
}

@test "print_missing_packages_installation(optional) does not print anything when there are no missing optional packages" {
	declare -a missing_optional_packages__keys=()
	run print_missing_packages_installation "optional"
	assert_output ""
}

@test "print_missing_packages_installation(required) when using Homebrew" {
	declare -a missing_required_packages__keys=()
	brew_path="/path/to/brew"

	expected_output=$(
		cat <<-'EOF'
			Use Homebrew to install missing required packages:

			  brew install pkg1 pkg2 pkg3
		EOF
	)

	missing_required_package "pkg1"
	missing_required_package "pkg2"
	missing_required_package "pkg3"

	run print_missing_packages_installation "required"
	assert_output "$expected_output"
}

@test "print_missing_packages_installation(required) when using APT" {
	declare -a missing_required_packages__keys=()
	apt_path="/path/to/apt-get"

	expected_output=$(
		cat <<-'EOF'
			Use APT to install missing required packages:

			  apt-get install -y pkg1 pkg2 pkg3
		EOF
	)

	missing_required_package "pkg1"
	missing_required_package "pkg2"
	missing_required_package "pkg3"

	run print_missing_packages_installation "required"
	assert_output "$expected_output"
}

@test "print_missing_packages_installation(required) when using DNF" {
	declare -a missing_required_packages__keys=()
	dnf_path="/path/to/dnf"

	expected_output=$(
		cat <<-'EOF'
			Use DNF to install missing required packages:

			  dnf install -y pkg1 pkg2 pkg3
		EOF
	)

	missing_required_package "pkg1"
	missing_required_package "pkg2"
	missing_required_package "pkg3"

	run print_missing_packages_installation "required"
	assert_output "$expected_output"
}

@test "print_missing_packages_installation(optional) when using Homebrew" {
	declare -a missing_optional_packages__keys=()
	brew_path="/path/to/brew"

	expected_output=$(
		cat <<-'EOF'
			Use Homebrew to install missing optional packages:

			  brew install pkg1 pkg2 pkg3
		EOF
	)

	missing_optional_package "pkg1"
	missing_optional_package "pkg2"
	missing_optional_package "pkg3"

	run print_missing_packages_installation "optional"
	assert_output "$expected_output"
}

@test "print_missing_packages_installation(optional) when using APT" {
	declare -a missing_optional_packages__keys=()
	apt_path="/path/to/apt-get"

	expected_output=$(
		cat <<-'EOF'
			Use APT to install missing optional packages:

			  apt-get install -y pkg1 pkg2 pkg3
		EOF
	)

	missing_optional_package "pkg1"
	missing_optional_package "pkg2"
	missing_optional_package "pkg3"

	run print_missing_packages_installation "optional"
	assert_output "$expected_output"
}

@test "print_missing_packages_installation(optional) when using DNF" {
	declare -a missing_optional_packages__keys=()
	dnf_path="/path/to/dnf"

	expected_output=$(
		cat <<-'EOF'
			Use DNF to install missing optional packages:

			  dnf install -y pkg1 pkg2 pkg3
		EOF
	)

	missing_optional_package "pkg1"
	missing_optional_package "pkg2"
	missing_optional_package "pkg3"

	run print_missing_packages_installation "optional"
	assert_output "$expected_output"
}

@test "print_missing_packages_table(required) does not print anything when there are no missing required packages" {
	declare -a missing_required_packages__keys=()
	run print_missing_packages_table "required"
	assert_output ""
}

@test "print_missing_packages_table(optional) does not print anything when there are no missing optional packages" {
	declare -a missing_optional_packages__keys=()
	run print_missing_packages_table "optional"
	assert_output ""
}

@test "print_missing_packages_table(required)" {
	declare -a missing_required_packages__keys=()
	declare -a missing_required_packages__values=()

	expected_output=$(
		cat <<-'EOF'

			The following required packages are missing:

			  pkg1                  Description for package 1
			  pkg2                  Description for package 2
			  pkg3                  Description for package 3
		EOF
	)

	missing_required_package "pkg1" "Description for package 1"
	missing_required_package "pkg2" "Description for package 2"
	missing_required_package "pkg3" "Description for package 3"

	run print_missing_packages_table "required"
	assert_output "$expected_output"
}

@test "print_missing_packages_table(optional)" {
	declare -a missing_optional_packages__keys=()
	declare -a missing_optional_packages__values=()

	expected_output=$(
		cat <<-'EOF'

			The following optional packages are missing:

			  pkg1                  Description for package 1
			  pkg2                  Description for package 2
			  pkg3                  Description for package 3
		EOF
	)

	missing_optional_package "pkg1" "Description for package 1"
	missing_optional_package "pkg2" "Description for package 2"
	missing_optional_package "pkg3" "Description for package 3"

	run print_missing_packages_table "optional"
	assert_output "$expected_output"
}

@test "should_install_without_pear() returns success status code when PHP_WITHOUT_PEAR is set to anything other than 'no'" {
	# shellcheck disable=SC2031
	export PHP_WITHOUT_PEAR=yes
	should_install_without_pear
}

@test "should_install_without_pear() returns failure status code when PHP_WITHOUT_PEAR is not set or is set to 'no'" {
	run ! should_install_without_pear
}

@test "update_pkg_config_path() returns without doing anything if Homebrew is not present" {
	brew_path=
	PKG_CONFIG_PATH="/usr/local:/usr"

	update_pkg_config_path "foo"
	[ "$PKG_CONFIG_PATH" = "/usr/local:/usr" ]
}

@test "update_pkg_config_path() returns without doing anything if brew does not find package" {
	brew_path="/path/to/brew"
	PKG_CONFIG_PATH="/usr/local:/usr"

	/path/to/brew() {
		return 1
	}

	update_pkg_config_path "foo"
	[ "$PKG_CONFIG_PATH" = "/usr/local:/usr" ]
}

@test "update_pkg_config_path() returns without doing anything if package directory does not exist" {
	brew_path="/path/to/brew"
	PKG_CONFIG_PATH="/usr/local:/usr"

	/path/to/brew() {
		printf "/this/directory/should/not/exist/on/your/system"
	}

	update_pkg_config_path "foo"
	[ "$PKG_CONFIG_PATH" = "/usr/local:/usr" ]
}

@test "update_pkg_config_path() sets the PKG_CONFIG_PATH variable" {
	brew_path="/path/to/brew"
	PKG_CONFIG_PATH="/usr/local:/usr"

	/path/to/brew() {
		printf "%s" "${tmp_dir}"
	}

	update_pkg_config_path "foo"
	[ "$PKG_CONFIG_PATH" = "${tmp_dir}/lib/pkgconfig:/usr/local:/usr" ]
}
