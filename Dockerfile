FROM php:7.2

ARG COMPOSER_FLAGS='--prefer-dist --ignore-platform-reqs --optimize-autoloader'
ARG PMVERSION=master

ENV COMPOSER_FLAGS=${COMPOSER_FLAGS}

RUN apt-get update && apt-get install -y build-essential supervisor r2c unzip python cron nano file && \
    libfreetype6-dev libjpeg-dev libgmp-dev libmpdec-dev libpq-dev libsodium-dev libmhash-dev libmcrypt-dev && \
    mariadb-client libmagickwand-dev  --no-install-recommends && \
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
