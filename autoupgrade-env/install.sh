#!/bin/bash

source .env
source ../lib/autoupgrade-lib.sh

# Working directories
export RELEASE_DIRECTORY=./release
export LOGS_DIRECTORY=./logs
export CACHE_DIRECTORY=../cache

mkdir -p "$RELEASE_DIRECTORY"
mkdir -p "$LOGS_DIRECTORY"
mkdir -p "$CACHE_DIRECTORY"

# Remove previous executions
rm -rf ./"$RELEASE_DIRECTORY"/*
rm -rf ./"$LOGS_DIRECTORY"/*

docker compose down --volumes --remove-orphans

if dpkg --compare-versions "$PRESTASHOP_VERSION" ge 9.0.0; then
  export PRESTASHOP_WORK_BASE_VERSION=8.1-fpm
  docker compose build work-base
else
  docker compose build work-base
fi

# Install Prestashop. Stop process on error
# Params:
#   $1 - release to install. ex: 8.0.5
#
install() {
  echo "--- Installation of v$1 ---"
  docker compose run -u "$DOCKER_USER_ID" --rm -v ./:/var/www/html/ -w /var/www/html/"$RELEASE_DIRECTORY"/"$1" work-base php install/index_cli.php \
    --step=all --db_server=mysql:3306 --db_name=prestashop --db_DOCKER_USER_ID=root --db_password="$MYSQL_ROOT_PASSWORD" --prefix=ps_ --db_clear=1 \
    --domain=localhost:8002 --firstname="Marc" --lastname="Beier" \
    --password="$BO_PASSWORD" --email="$BO_EMAIL" --language=en --country=us \
    --newsletter=0 --send_email=0 --ssl=0 >"$LOGS_DIRECTORY"/"$1"_install

  if grep -qiE 'fatal|error' "$LOGS_DIRECTORY"/"$1"_install; then
    echo "Docker command failed. See $LOGS_DIRECTORY/$1_install. Stopping the script (v$1)."
    exit 1
  fi

  echo "--- Installation of v$1 done ---"
}

# Download and build development branch.
# The contents of the ZIP are copied to the releases folder under the version name
# Params:
#   $1 - release to build. ex: 8.0.5
#
build_dev_release() {
  echo "--- Download v$1 Prestashop and build release ---"
  docker compose run -u "$DOCKER_USER_ID" --rm -v ./:/var/www/html/ -w /var/www/html/$RELEASE_DIRECTORY work-base /bin/sh -c \
    "git clone --depth 1 https://github.com/PrestaShop/PrestaShop.git;
    cd PrestaShop;
    git checkout $PRESTASHOP_DEVELOPMENT_BRANCH;
    php tools/build/CreateRelease.php --version=$1 --destination-dir=$1;
    mv $1/prestashop_$1.zip ../;
    cd ..;
    rm -rf PrestaShop;
    unzip -o prestashop_$1.zip -d $1 >/dev/null;
    rm prestashop_$1.zip;
    cd $1 || exit;
    unzip -o prestashop.zip >/dev/null;
    mv admin $ADMIN_DIR;
    rm prestashop.zip;"

  if [ ! $? -eq 0 ]; then
    echo "Build release v$1 fail"
    exit 1
  fi

  echo "--- Download v$1 Prestashop and build release done ---"
  echo ""
}

install_and_build_new_module_ui() {
  echo "--- Install and build new module UI ---"
  docker compose run --rm -v ./:/var/www/html/ -w /var/www/html/$RELEASE_DIRECTORY/$PRESTASHOP_VERSION/modules/autoupgrade/_dev work-base /bin/sh -c \
    "npm i;
     npm run vite:build;"

  if [ ! $? -eq 0 ]; then
    echo "Install and build new module UI fail"
    exit 1
  fi

  echo "--- Install and build new module UI done ---"
  echo ""
}

docker compose up -d mysql

if [ $? -ne 0 ]; then
  echo "Docker compose command failed. Stopping process."
  exit 1
fi

if [[ "$PRESTASHOP_DEVELOPMENT_VERSION" == true ]]; then
  build_dev_release "$PRESTASHOP_VERSION"
  install "$PRESTASHOP_VERSION"
else
  download_release "$PRESTASHOP_VERSION"
  sleep 10
  install "$PRESTASHOP_VERSION"
fi

install_module "$PRESTASHOP_VERSION"
install_and_build_new_module_ui
mv "$RELEASE_DIRECTORY"/"$PRESTASHOP_VERSION"/install "$RELEASE_DIRECTORY"/"$PRESTASHOP_VERSION"/install-dev

if dpkg --compare-versions "$PRESTASHOP_VERSION" ge 9.0.0; then
  export PRESTASHOP_RUN_VERSION=8.1-apache
  docker compose build prestashop-run
else
  docker compose build prestashop-run
fi

docker compose up -d prestashop-run

if [ $? -ne 0 ]; then
  echo "Docker compose command failed. Stopping process."
  exit 1
fi

echo "--- Docker container created for test module environment, see result at http://localhost:8002/$ADMIN_DIR ---"
