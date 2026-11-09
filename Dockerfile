# Moodle (estrutura com /public) para Coolify
FROM php:8.3-apache-bookworm

ENV MOODLE_DIR=/var/www/moodle \
    MOODLE_DATA=/var/www/moodledata

# Dependências de sistema + extensões PHP exigidas pelo Moodle
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq-dev libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
        libwebp-dev libicu-dev libxml2-dev unzip git ghostscript \
        postgresql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" pgsql gd intl zip soap exif opcache \
    && apt-get purge -y --auto-remove libpq-dev libzip-dev libpng-dev libjpeg62-turbo-dev \
        libfreetype6-dev libwebp-dev libicu-dev libxml2-dev \
    && apt-get install -y --no-install-recommends libpq5 libzip4 libpng16-16 libjpeg62-turbo \
        libfreetype6 libwebp7 libicu72 libxml2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Configurações do PHP e Apache
COPY docker/php-moodle.ini /usr/local/etc/php/conf.d/zz-moodle.ini
COPY docker/apache-moodle.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite headers expires

# Código do Moodle
WORKDIR ${MOODLE_DIR}
COPY --chown=www-data:www-data . ${MOODLE_DIR}
COPY --chown=www-data:www-data docker/config.php ${MOODLE_DIR}/config.php

# Dependências PHP (a pasta vendor/ não vem no repositório)
RUN composer install --no-dev --no-interaction --no-progress --optimize-autoloader \
    && chown -R www-data:www-data ${MOODLE_DIR}/vendor \
    && rm -rf /root/.composer

RUN mkdir -p ${MOODLE_DATA} && chown www-data:www-data ${MOODLE_DATA}

COPY docker/entrypoint.sh /usr/local/bin/moodle-entrypoint
RUN chmod +x /usr/local/bin/moodle-entrypoint

VOLUME ["/var/www/moodledata"]
EXPOSE 80

ENTRYPOINT ["moodle-entrypoint"]
CMD ["apache2-foreground"]
