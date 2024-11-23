# asdf-php

A [PHP](https://www.php.net) plugin for the [asdf version manager](https://asdf-vm.com).

_Original version of this plugin created by [@Stratus3D](https://github.com/Stratus3D)_

## Supported Versions of PHP

- 8.1
- 8.2
- 8.3
- 8.4

## Installing the Plugin

```bash
asdf plugin add php https://github.com/ramsey/asdf-php.git
```

## Updating the Plugins

To get the latest changes to this plugin, use the following to update your local copy of the plugin to the latest commit on the default branch.

```bash
asdf plugin update php
```

## Installing a PHP Version

```bash
asdf install php <version>
```

If you are missing any required dependencies, the installer will provide details on which packages are missing and how to install them on your system.

> [!NOTE]
> Composer is installed globally alongside PHP, by default.

> [!TIP]
> If you require additional PHP extensions, you may install them using `pecl`, which is also installed alongside PHP. For example:
>
> ```bash
> pecl install redis
> pecl install imagick
>
> echo "extension=redis" > $(asdf where php)/etc/php.d/redis.ini
> echo "extension=imagick" > $(asdf where php)/etc/php.d/imagick.ini
> ```

### macOS

To install PHP on macOS, you'll need the [Xcode command line tools](https://developer.apple.com/xcode/resources/) and [Homebrew](https://brew.sh).

### Optional Packages

While installing, you might see a message in the output about missing optional packages. asdf will continue building PHP. However, you may use `Ctrl-C` to stop the build and install any optional packages you wish to include.

The message about optional packages will look something like this:

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

### PEAR

If you wish to exclude PEAR from your PHP installation, specify the `PHP_WITHOUT_PEAR` variable with any value (except "no"), e.g.:

```bash
PHP_WITHOUT_PEAR=yes asdf install php <version>
```

## Usage

Check the [asdf documentation](https://asdf-vm.com/manage/versions.html) for instructions on how to install & manage versions.

## Global Composer Dependencies

Composer is installed globally alongside PHP, by default. If you install any Composer packages globally, you'll need to run the `reshim` command. Afterward, you will be able to execute the command directly.

```shell
composer global require friendsofphp/php-cs-fixer
asdf reshim
php-cs-fixer --version
```

## License

Licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
