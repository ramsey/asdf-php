# asdf-php

A [PHP](https://www.php.net) plugin for the [asdf version manager](https://asdf-vm.com).

_Original version of this plugin created by [@Stratus3D](https://github.com/Stratus3D)_

> [!WARNING]
> This is an experimental plugin for asdf that uses [Static PHP](https://static-php.dev) binaries instead of building PHP from source. As such, there are a few things that might not work as expected.
>
> Currently, this plugin installs the [static-php-cli "bulk" binaries](https://github.com/crazywhalecc/static-php-cli?tab=readme-ov-file#direct-download), which include [many extensions](https://dl.static-php.dev/static-php-cli/bulk/build-extensions.json), but they might be missing some extensions you need. If that's the case, please open an issue on this repository, so I can keep track of what's missing that users need.

> [!IMPORTANT]
> Because this plugin uses Static PHP binaries, it does not include `php-config` or `phpize`, so it is not possible to build additional PHP extensions. While this plugin installs [Composer](https://getcomposer.org) globally alongside PHP, it does not yet install [pie](https://github.com/php/pie), for installing PHP extensions.
>
> See the Static PHP FAQ answer for "[Can statically-compiled PHP install extensions?](https://static-php.dev/en/faq/#can-statically-compiled-php-install-extensions)."

> [!NOTE]
> An earlier experimental version of this plugin exists in the [nextgen branch](https://github.com/ramsey/asdf-php/tree/nextgen). It builds PHP from source and attempts to locate any missing dependencies to inform the user how to install them before they can continue. It can take a while to build PHP from source, and due to the dynamic library linking, anytime you update Homebrew packages, it can break PHP. This is why I'm experimenting with the static binaries approach.

## Installing the Plugin

```bash
asdf plugin add php https://github.com/ramsey/asdf-php.git
```

## Updating the Plugin

To get the latest changes to this plugin, use the following to update your local copy of the plugin to the latest commit on the default branch.

```bash
asdf plugin update php
```

> [!TIP]
> If you previously installed this plugin when the default branch was `nextgen` and you wish to update to the `static-php` branch, the easiest way to do so is to uninstall and reinstall the plugin:
>
> ```bash
> asdf plugin remove php
> asdf plugin add php https://github.com/ramsey/asdf-php.git
> ```

## Installing a PHP Version

```bash
asdf install php [version]
```

### Installing Composer

The latest version of Composer is always installed alongside PHP. You don't need to do anything extra to install it.

### Installing php-fpm

To include [php-fpm](https://www.php.net/manual/en/install.fpm.php) in your PHP installation, use the `ASDF_PHP_FPM` environment variable:

```bash
ASDF_PHP_FPM=1 asdf install php [version]
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
