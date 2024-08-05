# Utility script to quickly test the rollback process in autoupgrade module

The script allows testing the rollback between 2 versions of PrestaShop, with the possibility of :
- create a database dump before upgrade and comparing it with another dump created after the rollback
- create file hashes before upgrade and comparing it with another hashes created after the rollback

The entire process is containerized.

## Prerequisites

- OS: Linux
- Tools:
  - Docker (with compose plugin)
  - jq (https://jqlang.github.io/jq/)

## How it works ?

Configure the [.env](.env) file, and run:

```shell
$ ./rollback.sh
```

4 directories will be created:

- dumps: contains generated SQL dumps and diffs
- logs: contains installs and upgrades logs
- releases: contains Prestashop releases
- checksums: contains generated hashes and diffs

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
