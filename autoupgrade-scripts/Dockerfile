ARG VERSION

FROM prestashop/base:$VERSION

ARG NODE_VERSION
ARG USER_ID
ARG GROUP_ID

RUN mkdir -p  /.npm
RUN chown -R $USER_ID:$GROUP_ID /.npm

ENV NVM_DIR       /usr/local/nvm
RUN apt-get update && apt-get install -y git zip

ENV NODE_PATH     $NVM_DIR/versions/node/v$NODE_VERSION/bin
ENV PATH          $PATH:$NODE_PATH

ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION

RUN php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php
