# Utility script to quickly test the autoupgrade module

The script allows testing the module autoupgrade in specific version of Prestashop.

The entire process is containerized.

## Prerequisites

- OS: Linux
- Tools: Docker (with compose plugin)

## How it works ?

Configure the [.env](.env) file, and run:

```shell
$ ./install.sh
```

2 directories will be created:

- logs: contains installs and upgrades logs
- release: contains Prestashop release

The updated store is available at http://localhost:8002/admin1234 (by default) after process

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
