FROM phpswoole/swoole:4.4.14-php7.2

ARG COMPOSER_FLAGS='--prefer-dist --ignore-platform-reqs --optimize-autoloader'
ARG version=dev-master
ARG http_version=dev-master

ENV COMPOSER_FLAGS=${COMPOSER_FLAGS}

RUN useradd --create-home www-data

RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm:${version} && composer require php-pm/httpkernel-adapter:${http_version}

RUN \
    pecl update-channels         && \
    pecl install redis           && \
    pecl install ffmpeg           && \
    docker-php-ext-enable redis  && \
    docker-php-ext-enable ffmpeg  && \
    docker-php-ext-install opcache pcntl pdo_mysql && \
    install-swoole-ext.sh async      4.4.14                                   && \
    install-swoole-ext.sh postgresql 4.4.14                                   && \
    install-swoole-ext.sh orm        877667f36a0ed2ddaf4bec8f3ca86550766cf119 && \
    install-swoole-ext.sh serialize  84982d6f6c68e000c1dbbae3bc46d3630ffef798 && \
    docker-php-ext-enable swoole_async swoole_postgresql swoole_orm swoole_serialize opcache pcntl pdo_mysql
	
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

EXPOSE 8080
