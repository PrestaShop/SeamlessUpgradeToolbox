# Utility script to quickly test the autoupgrade module

The script allows testing the upgrade between 2 versions of PrestaShop, with the possibility of:

- create a database dump and comparing it with a dump from a fresh install
- create file hashes and comparing it with another hashes from a fresh install

A "recursive" mode is available and allows performing all updates between 2 versions.

The entire process is containerized.

> [!IMPORTANT]  
> Work only for v7.0.0+ of autoupgrade module.

## Prerequisites

- OS: Linux / Mac
- Tools:
  - Docker (with compose plugin)
  - jq (https://jqlang.github.io/jq/)
  - dpkg

### For Mac M2

You may need to update the mysql service in the `docker-compose.yml` file and add the platform:

```yaml
services:
     mysql:
         platform: linux/x86_64
         image: mysql:5.7
```

## How it works ?

Configure the [.env](.env) file, and run:

```shell
$ ./upgrade.sh
```

4 directories will be created:

- dumps: contains generated SQL dumps and diffs
- logs: contains installs and upgrades logs
- releases: contains Prestashop releases
- checksums: contains generated hashes and diffs

The updated store is available at http://localhost:8002/admin1234 (by default) after process

### Configuration

Important variables you may need to adapt for your test:

BASE_VERSION: define which version you start the upgrade from
UPGRADE_VERSION: define which version you are upgrading to
AUTOUPGRADE_GIT_REPO: the repository of the autoupgrade module to test (either the default one or your fork)
AUTOUPGRADE_GIT_BRANCH: the branch used on the repository (probably your PR branch that needs to contain the changes you are testing)

PRESTASHOP_WORK_BASE_VERSION: The PHP version used for the shop (ex: 8.1-fpm for 9.0 version)
PRESTASHOP_RUN_VERSION: The PHP version used while running the autoupgrade (ex: 8.1-apache for 9.0 version)

Note: Both PRESTASHOP_WORK_BASE_VERSION and PRESTASHOP_RUN_VERSION should be adapted automatically when upgrading towards v9.0 as long as `dpkg` is installed on your env

### Cache folder

The upgrade tool is able to download the target versions automatically as long as they have been released, if you need to test a version under development you have to provide the ZIP and XML checksum yourself.
For example to test the upgrade towards 9.0.0 (if it has never been released) you need to copy `9.0.0.zip` and `9.0.0.xml` into the `cache` folder at the root of this project (one folder upper from the current one).

## Available versions

- 1.7.0.0 and its patch versions
- 1.7.1.0 and its patch versions
- 1.7.2.0 and its patch versions
- 1.7.3.0 and its patch versions
- 1.7.4.0 and its patch versions
- 1.7.5.0 and its patch versions
- 1.7.6.0 and its patch versions
- 1.7.7.0 and its patch versions
- 1.7.8.0 and its patch versions
- 8.0.0 and its patch versions
- 8.1.0 and its patch versions
- 9.0.0 (dev version)
