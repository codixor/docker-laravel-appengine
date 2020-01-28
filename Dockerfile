FROM php:7.2

ARG COMPOSER_FLAGS='--prefer-dist --ignore-platform-reqs --optimize-autoloader'
ARG PMVERSION=master

ENV COMPOSER_FLAGS=${COMPOSER_FLAGS}

RUN apt-get update && apt-get install -y supervisor libmpdec-dev libpq-dev build-essential libsodium-dev unzip python cron libfreetype6-dev && \
    libjpeg62-turbo-dev libfreetype6 libjpeg-dev libgmp-dev re2c libmhash-dev libmcrypt-dev file && \
    mariadb-client libmagickwand-dev nano --no-install-recommends && \
    ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ && \
    pecl update-channels && \
    pecl install redis   && \
	pecl install imagick && \
	pecl install decimal && \
	pecl install swoole && \
	docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \		
	docker-php-ext-install opcache pcntl pdo_mysql gd gmp bcmath sockets && \
	docker-php-ext-enable imagick redis swoole pcntl  pdo_mysql gd bcmath sockets decimal && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm:2.0.3

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
