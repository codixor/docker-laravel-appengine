FROM composer:1.9 as composer

ARG version=dev-master
ARG http_version=dev-master
RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm:${version}

FROM phpswoole/swoole:4.4.14-php7.2 as phpswoole

ARG COMPOSER_FLAGS='--prefer-dist --ignore-platform-reqs --optimize-autoloader'
ARG PMVERSION=master

ENV COMPOSER_FLAGS=${COMPOSER_FLAGS}

RUN \
    pecl update-channels         && \
    pecl install redis           && \
    docker-php-ext-enable redis  && \
    docker-php-ext-install opcache pcntl pdo_mysql && \
    install-swoole-ext.sh async      4.4.14                                   && \
    install-swoole-ext.sh postgresql 4.4.14                                   && \
    install-swoole-ext.sh orm        877667f36a0ed2ddaf4bec8f3ca86550766cf119 && \
    install-swoole-ext.sh serialize  84982d6f6c68e000c1dbbae3bc46d3630ffef798 && \
    docker-php-ext-enable swoole_async swoole_postgresql swoole_orm swoole_serialize opcache pcntl pdo_mysql
	
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
