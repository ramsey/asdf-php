# asdf-php

A [PHP](https://www.php.net) plugin for the [asdf version manager](https://asdf-vm.com).

_Original version of this plugin created by [@Stratus3D](https://github.com/Stratus3D)_

## Installing the Plugin

```bash
asdf plugin add php https://github.com/ramsey/asdf-php.git
```

## Updating the Plugin

To get the latest changes to this plugin, use the following to update your local copy of the plugin to the latest commit on the default branch.

```bash
asdf plugin update php
```

## Installing a PHP Version

```bash
asdf install php <version>
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
