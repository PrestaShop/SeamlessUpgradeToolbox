#!/bin/bash

# Download ZIP for initial install.
# The contents of the ZIP are copied to the releases folder under the version name
# Params:
#   $1 - release to download. ex: 8.0.5
#
download_release() {
  echo "--- Download v$1 Prestashop release ---"

  if [ -e "$CACHE_DIRECTORY"/"$1".zip ]; then
    echo "Cache detected ! skip download zip"
    cp "$CACHE_DIRECTORY"/"$1".zip "$RELEASE_DIRECTORY"/prestashop_"$1".zip
  else
    docker compose run -u "$DOCKER_USER_ID" --rm -v $(pwd):/var/www/html/ -w /var/www/html/"$RELEASE_DIRECTORY" work-base \
      curl --fail -LO https://github.com/PrestaShop/zip-archives/raw/main/prestashop_"$1".zip

    if [ ! $? -eq 0 ]; then
      echo "Download v$1 Prestashop release zip fail, see" https://github.com/PrestaShop/zip-archives/raw/main/prestashop_"$1".zip
      exit 1
    fi
    cp "$RELEASE_DIRECTORY"/prestashop_"$1".zip "$CACHE_DIRECTORY"/"$1".zip
  fi

  docker compose run -u "$DOCKER_USER_ID" --rm -v $(pwd):/var/www/html/ -w /var/www/html/"$RELEASE_DIRECTORY" work-base /bin/sh -c \
    "unzip -o prestashop_$1.zip -d $1 >/dev/null;
     rm prestashop_$1.zip;
     cd $1 || exit;
     unzip -o prestashop.zip >/dev/null;
     rm prestashop.zip;
     mkdir admin/autoupgrade/download;
     mv admin $ADMIN_DIR;
     cp -r ../$1 ../$1_base;"

  echo "--- Download v$1 Prestashop release done ---"
  echo ""
}

# Download ZIP and XML for upgrade. This will place them in the folder "$RELEASE_DIRECTORY"/"$BASE_VERSION"/"$ADMIN_DIR"/autoupgrade/download.
# The contents of the ZIP are also copied to the releases folder under the version name
# Params:
#   $1 - release to download. ex: 8.0.5
#
download_release_and_xml() {
  echo "--- Download v$1 Prestashop release and xml MD5 ---"

  if [ -e "$CACHE_DIRECTORY"/"$1".zip ]; then
    echo "Cache detected ! skip download zip"
    cp "$CACHE_DIRECTORY"/"$1".zip "$RELEASE_DIRECTORY"/"$BASE_VERSION"/"$ADMIN_DIR"/autoupgrade/download/prestashop_"$1".zip
  else
    docker compose run -u "$DOCKER_USER_ID" --rm -v $(pwd):/var/www/html/ -w /var/www/html/"$RELEASE_DIRECTORY"/"$BASE_VERSION" work-base \
      curl --fail -L https://github.com/PrestaShop/zip-archives/raw/main/prestashop_"$1".zip -o "$ADMIN_DIR"/autoupgrade/download/prestashop_"$1".zip

    if [ ! $? -eq 0 ]; then
      echo "Download v$1 Prestashop release zip fail, see" https://github.com/PrestaShop/zip-archives/raw/main/prestashop_"$1".zip
      exit 1
    fi
    cp "$RELEASE_DIRECTORY"/"$BASE_VERSION"/"$ADMIN_DIR"/autoupgrade/download/prestashop_"$1".zip "$CACHE_DIRECTORY"/"$1".zip
  fi

  if [ -e "$CACHE_DIRECTORY"/"$1".xml ]; then
    echo "Cache detected ! skip download xml"
    cp "$CACHE_DIRECTORY"/"$1".xml "$RELEASE_DIRECTORY"/"$BASE_VERSION"/"$ADMIN_DIR"/autoupgrade/download/prestashop_"$1".xml
  else
    docker compose run -u "$DOCKER_USER_ID" --rm -v $(pwd):/var/www/html/ -w /var/www/html/"$RELEASE_DIRECTORY"/"$BASE_VERSION" work-base \
      curl --fail -L https://api.prestashop.com/xml/md5/"$1".xml -o "$ADMIN_DIR"/autoupgrade/download/prestashop_"$1".xml

    if [ ! $? -eq 0 ]; then
      echo "Download v$1 Prestashop release xml fail, see" https://api.prestashop.com/xml/md5/"$1".xml
      exit 1
    fi
    cp "$RELEASE_DIRECTORY"/"$BASE_VERSION"/"$ADMIN_DIR"/autoupgrade/download/prestashop_"$1".xml "$CACHE_DIRECTORY"/"$1".xml
  fi

  docker compose run -u "$DOCKER_USER_ID" --rm -v $(pwd):/var/www/html/ -w /var/www/html/"$RELEASE_DIRECTORY" work-base /bin/sh -c \
    "cp $BASE_VERSION/"$ADMIN_DIR"/autoupgrade/download/prestashop_"$1".zip .
    unzip -o prestashop_$1.zip -d $1 >/dev/null;
    rm prestashop_$1.zip;
    cd $1 || exit;
    unzip -o prestashop.zip >/dev/null;
    rm prestashop.zip;"

  if [ ! $? -eq 0 ]; then
    echo "Unzip v$1 Prestashop release fail"
    exit 1
  fi

  echo "--- Download v$1 Prestashop release and xml MD5 done ---"
}

# Download autoupgrade module
# Params:
#   $1 - release location for module. ex: 8.0.5
#
install_module() {
  echo "--- Install autoupgrade module (dev version) --- "
  docker compose run -u "$DOCKER_USER_ID" --rm -w /app/"$RELEASE_DIRECTORY"/"$1" composer /bin/sh -c \
    "cd modules;
     git clone $AUTOUPGRADE_GIT_REPO;
     cd autoupgrade;
     git checkout $AUTOUPGRADE_GIT_BRANCH;
     composer install;"

  if [ ! $? -eq 0 ]; then
    echo "Install autoupgrade module fail"
    exit 1
  fi

  echo "--- Install autoupgrade module (dev version) done ---"
  echo ""
}

# Clean modules, for development purpose only
clean_modules() {
  docker compose run -u "$DOCKER_USER_ID" --rm -v $(pwd):/var/www/html/ -w /var/www/html/"$RELEASE_DIRECTORY"/"$BASE_VERSION" work-base /bin/sh -c \
    "cp -r modules/autoupgrade .;
    rm -rf modules/*;
    mv autoupgrade modules/;"
}

# Params:
#   $1 - Prestashop release target. ex: 8.0.5
#
create_DB_schema() {
  echo "--- Create database schema for $1 ---"
  version="${1//./}"
  docker compose run --rm mysql mysql -hmysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE presta_$version;"
  echo "--- Create database schema for $1 done ---"
  echo ""
}

# Params:
#   $1 - Actual Prestashop version. ex: 8.0.5
#   $2 - Prestashop release destination. ex: 8.1.7
upgrade() {
  if [[ "$PERFORM_ONLY_CORE_DATABASE_UPGRADE" == true ]]; then
    clean_modules
  fi

  download_release_and_xml "$2"
  upgrade_process "$1" "$2"
}

# Params:
#   $1 - Actual Prestashop version. ex: 8.0.5
#   $2 - Prestashop release destination. ex: 8.1.7
upgrade_experimental() {
  if [[ "$PERFORM_ONLY_CORE_DATABASE_UPGRADE" == true ]]; then
    clean_modules
  fi

  build_dev_release "$2"
  upgrade_process "$1" "$2"
}

check_app_ports() {
  if ss -tuln | grep -qE ":($PRESTASHOP_RUN_PORT|$MYSQL_PORT)"; then
    echo "Port 3306 or 8002 is used, please free it for the script to work properly."
    exit 1
  fi
}
