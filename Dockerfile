FROM phpswoole/swoole:4.4.14-php7.2 gcr.io/google-appengine/php72:latest

ARG COMPOSER_FLAGS='--prefer-dist --ignore-platform-reqs --optimize-autoloader'
ENV COMPOSER_FLAGS=${COMPOSER_FLAGS}
ENV DOCUMENT_ROOT=/app/public
ARG version=dev-master
ARG http_version=dev-master

COPY . $APP_DIR

RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm:${version} && composer require php-pm/httpkernel-adapter:${http_version}

RUN \
    pecl update-channels         && \
    pecl install redis           && \
    docker-php-ext-enable redis  && \
    docker-php-ext-install pcntl && \
	install-swoole-ext.sh async      4.4.14                                   && \
    install-swoole-ext.sh postgresql 4.4.14                                   && \
    install-swoole-ext.sh orm        877667f36a0ed2ddaf4bec8f3ca86550766cf119 && \
    install-swoole-ext.sh serialize  84982d6f6c68e000c1dbbae3bc46d3630ffef798 && \
    docker-php-ext-enable swoole_async swoole_postgresql swoole_orm swoole_serialize && \
	chown -R www-data.www-data $APP_DIR && /build-scripts/composer.sh;
	
ENTRYPOINT ["/build-scripts/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

EXPOSE 8080
