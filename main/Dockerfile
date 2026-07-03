ARG MOODLE_IMAGE_VERSION=4.5.11.056

############################
## STAGE: build
####################################################################################
FROM ctezlifrn/avamoodlebase:$MOODLE_IMAGE_VERSION AS build

ARG AVA_IMAGE_VERSION=ava_image_not_built
ARG NVM_INSTALL_SHA256

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ADD build/plugins /tmp/build/plugins
WORKDIR /tmp/build/plugins

# Lista de repositórios otimizada em um array para facilitar manutenção
RUN REPOS=" \
        suap-ava-suite/moodle-tool_painelava \
        suap-ava-suite/moodle-local_suap \
        suap-ava-suite/moodle-auth_suap \
        suap-moodletheme-suite/moodle-theme_suap \
        suap-moodletheme-suite/moodle-block_course_gallery \
        suap-moodletheme-suite/moodle-block_course_rating \
        suap-moodletheme-suite/moodle-block_recommendation \
        suap-moodletheme-suite/moodle-block_site_info \
        proitec-moodle-suite/moodle-mod_multiprogress \
        proitec-moodle-suite/moodle-block_multiprogress \
        proitec-moodle-suite/moodle-mod_mapaproitec \
        proitec-moodle-suite/moodle-mod_codexproitec \
        proitec-moodle-suite/moodle-mod_medalhasproitec \
    " \
    && for REPO in $REPOS; do \
        echo "Baixando $REPO..." \
        && URL=$(curl -s "https://api.github.com/repos/$REPO/releases" | jq -r 'map(select(.tag_name | endswith("-test") | not)) | .[0] | if .assets | length > 0 then .assets[0].browser_download_url else .zipball_url end') \
        && curl -sL "$URL" -o "$(basename $REPO).zip"; \
    done

RUN chown -R www-data:www-data /tmp/build/plugins

USER www-data
RUN for plugin in *.zip ; do /usr/local/bin/moodle-install-package.sh $plugin; done
RUN sed -i s/ava_image_not_built/$AVA_IMAGE_VERSION/g /var/www/html/readenv.php
# Moodle timeline format customization: enable message defaults by replacing
# MESSAGE_DEFAULT_LOGGEDIN + MESSAGE_DEFAULT_LOGGEDOFF with MESSAGE_DEFAULT_ENABLED
# in course/format/timeline/db/messages.php during image build.
RUN sed -i s/MESSAGE_DEFAULT_LOGGEDIN\ \+\ MESSAGE_DEFAULT_LOGGEDOFF/MESSAGE_DEFAULT_ENABLED/g /var/www/html/course/format/timeline/db/messages.php


############################
## STAGE: dev
############################
FROM build AS dev

ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=22.11.0
ENV PATH=${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash curl ca-certificates git xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${NVM_DIR} \
    && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh -o /tmp/nvm-install.sh \
    && echo "${NVM_INSTALL_SHA256}  /tmp/nvm-install.sh" | sha256sum -c - \
    && bash /tmp/nvm-install.sh \
    && rm -f /tmp/nvm-install.sh \
    && . ${NVM_DIR}/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm use ${NODE_VERSION} \
    && npm install -g grunt-cli

# Instala o Composer Globalmente
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN export COMPOSER_ALLOW_SUPERUSER=1 \
    && mkdir -p /opt/phpcs \
    && cd /opt/phpcs \
    && composer init --no-interaction \
    && composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true \
    && composer require moodlehq/moodle-cs \
    && ln -s /opt/phpcs/vendor/bin/phpcs /usr/local/bin/phpcs \
    && ln -s /opt/phpcs/vendor/bin/phpcbf /usr/local/bin/phpcbf

# Install PHPUnit globally (PHPUnit 11 for PHP 8.3 compatibility)
# Set this to the official SHA256 for the exact phpunit-11.phar being downloaded.
ARG PHPUNIT_11_PHAR_SHA256
RUN curl -fL https://phar.phpunit.de/phpunit-11.phar -o /usr/local/bin/phpunit \
    && echo "${PHPUNIT_11_PHAR_SHA256}  /usr/local/bin/phpunit" | sha256sum -c - \
    && chmod +x /usr/local/bin/phpunit

# Configure PCOV for PHPUnit coverage
RUN echo "pcov.enabled=1" >> /usr/local/etc/php/conf.d/20-pcov.ini \
    && echo "pcov.directory=." >> /usr/local/etc/php/conf.d/20-pcov.ini

USER www-data
WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]


############################
## STAGE: final
###################################################################################
FROM ctezlifrn/avamoodlebase:$MOODLE_IMAGE_VERSION

COPY --from=build --chown=www-data:www-data /var/www/html /var/www/html

USER www-data
WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]