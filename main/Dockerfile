ARG MOODLE_IMAGE_VERSION=4.5.11.056

############################
## STAGE: build
####################################################################################
FROM ctezlifrn/avamoodlebase:$MOODLE_IMAGE_VERSION AS build

ARG AVA_IMAGE_VERSION=ava_image_not_built
ARG NVM_INSTALL_SHA256

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        jq \
        ca-certificates \
        unzip \
        zip \
        rsync \
    && rm -rf /var/lib/apt/lists/*

ADD build/plugins /tmp/build/plugins
WORKDIR /tmp/build/plugins

RUN set -eux; \
    REPOS=" \
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
        proitec-moodle-suite/moodle-mod_medalhasproitec"; \
    for REPO in $REPOS; do \
        echo "=========================================================="; \
        echo "📦 Processando: $REPO"; \
        echo "=========================================================="; \
        API_FILE="/tmp/$(basename "$REPO").json"; \
        echo "➡️ Baixando releases..."; \
        curl -fsSL "https://api.github.com/repos/$REPO/releases" -o "$API_FILE"; \
        echo "➡️ Limpando caracteres de controle..."; \
        tr -d '\000-\037' < "$API_FILE" > "${API_FILE}.clean"; \
        mv "${API_FILE}.clean" "$API_FILE"; \
        echo "➡️ Validando JSON..."; \
        if ! jq empty "$API_FILE" >/dev/null 2>&1; then \
            echo "❌ JSON inválido ou resposta inesperada para $REPO"; \
            echo "===== CONTEÚDO RECEBIDO ====="; \
            cat "$API_FILE"; \
            echo "===== FIM DO CONTEÚDO ====="; \
            exit 1; \
        fi; \
        URL=$(jq -r 'if type == "array" and length > 0 then (map(select(.tag_name | endswith("-test") | not)) | if length > 0 then .[0] | (if .assets | length > 0 then .assets[0].browser_download_url else .zipball_url end) else "null" end) else "null" end' "$API_FILE"); \
        if [ "$URL" = "null" ] || [ -z "$URL" ]; then \
            echo "❌ Nenhuma release oficial encontrada para $REPO"; \
            echo "===== JSON PROCESSADO ====="; \
            cat "$API_FILE"; \
            echo "===== FIM ====="; \
            exit 1; \
        fi; \
        echo "✅ Release: $URL"; \
        curl -fsSL "$URL" -o "$(basename "$REPO").zip"; \
    done
    
RUN chown -R www-data:www-data /tmp/build/plugins

USER www-data

RUN set -eux; \
    for plugin in *.zip; do \
        echo "================================================"; \
        echo "📦 Processando $plugin"; \
        echo "================================================"; \
        \
        if echo "$plugin" | grep -q '^moodle-'; then \
            echo " -> Plugin dinâmico (GitHub) – instalação especial."; \
            \
            plugin_fullname=$(basename "$plugin" .zip | sed 's/^moodle-//'); \
            plugin_type=$(echo "$plugin_fullname" | cut -d '_' -f1); \
            plugin_name=$(echo "$plugin_fullname" | cut -d'_' -f2-); \
            \
            case $plugin_type in \
                auth)      target_dir="auth" ;; \
                mod)       target_dir="mod" ;; \
                block)     target_dir="blocks" ;; \
                tool)      target_dir="admin/tool" ;; \
                local)     target_dir="local" ;; \
                theme)     target_dir="theme" ;; \
                *)         echo "Tipo de plugin dinâmico desconhecido: $plugin_type"; exit 1 ;; \
            esac; \
            \
            plugin_dest="/var/www/html/$target_dir"; \
            mkdir -p "$plugin_dest"; \
            \
            temp_dir=$(mktemp -d); \
            unzip -q "$plugin" -d "$temp_dir"; \
            \
            echo " -> Estrutura do zip:"; \
            find "$temp_dir" -maxdepth 2; \
            \
            top_dirs=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d); \
            if [ "$(echo "$top_dirs" | wc -l)" -eq 1 ] && [ -f "$top_dirs/version.php" ]; then \
                echo " -> Zipball detectado, extraindo e renomeando para $plugin_name"; \
                # Copia o conteúdo da pasta interna para $plugin_dest/$plugin_name/
                mkdir -p "$plugin_dest/$plugin_name"; \
                rsync -a "$top_dirs"/ "$plugin_dest/$plugin_name/"; \
            else \
                echo " -> Asset normal, instalando como $plugin_name"; \
                mkdir -p "$plugin_dest/$plugin_name"; \
                rsync -a "$temp_dir"/ "$plugin_dest/$plugin_name/"; \
            fi; \
            rm -rf "$temp_dir"; \
        else \
            echo " -> Plugin estático (repo) – usando script original."; \
            /usr/local/bin/moodle-install-package.sh "$plugin"; \
        fi; \
    done
RUN sed -i s/ava_image_not_built/$AVA_IMAGE_VERSION/g /var/www/html/readenv.php

RUN sed -i \
    s/MESSAGE_DEFAULT_LOGGEDIN\ \+\ MESSAGE_DEFAULT_LOGGEDOFF/MESSAGE_DEFAULT_ENABLED/g \
    /var/www/html/course/format/timeline/db/messages.php


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
        bash \
        curl \
        ca-certificates \
        git \
        xz-utils \
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

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN export COMPOSER_ALLOW_SUPERUSER=1 \
    && mkdir -p /opt/phpcs \
    && cd /opt/phpcs \
    && composer init --no-interaction \
    && composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true \
    && composer require moodlehq/moodle-cs \
    && ln -s /opt/phpcs/vendor/bin/phpcs /usr/local/bin/phpcs \
    && ln -s /opt/phpcs/vendor/bin/phpcbf /usr/local/bin/phpcbf

ARG PHPUNIT_11_PHAR_SHA256
RUN curl -fL https://phar.phpunit.de/phpunit-11.phar -o /usr/local/bin/phpunit \
    && echo "${PHPUNIT_11_PHAR_SHA256}  /usr/local/bin/phpunit" | sha256sum -c - \
    && chmod +x /usr/local/bin/phpunit

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