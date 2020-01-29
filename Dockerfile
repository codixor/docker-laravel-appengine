FROM composer:1.9 as composer

RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm

FROM alpine:3.9

WORKDIR /app
# VOLUME /app

ENV SWOOLE_VERSION=4.4.14

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "UTC" | tee /etc/timezone && \
    apk del tzdata

RUN apk --no-cache add supervisor

RUN apk add --update curl wget bash openssl libstdc++ \
        openssl-dev php7-dev \
        autoconf make pkgconf g++ gcc build-base linux-headers \
        php7 php7-opcache php7-fpm php7-cgi php7-ctype php7-json php7-dom php7-zip php7-zip php7-gd \
        php7-curl php7-mbstring php7-mcrypt php7-bcmath php7-iconv php7-posix \
	    php7-pdo_mysql php7-tokenizer php7-simplexml php7-session php7-exif php7-pcntl php7-zlib \
        php7-xml php7-sockets php7-openssl php7-fileinfo php7-ldap php7-xmlwriter php7-phar \
        php7-intl php7-pecl-swoole

    && ln -sfv /usr/bin/php7 /usr/bin/php && ln -sfv /usr/bin/php-config7 /usr/bin/php-config && ln -sfv /usr/bin/phpize7 /usr/bin/phpize \

    && cd /tmp \
    && wget https://github.com/igbinary/igbinary/archive/3.1.2.zip \
    && unzip 3.1.2.zip && cd igbinary-3.1.2 \
    && /usr/bin/phpize7 && ./configure --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=igbinary.so >> /etc/php7/conf.d/01_igbinary.ini \

    && cd /tmp \
    && wget https://github.com/phpredis/phpredis/archive/5.1.1.zip \
    && unzip 5.1.1.zip && cd phpredis-5.1.1 \
    && /usr/bin/phpize7 && ./configure --enable-redis-igbinary --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=redis.so >> /etc/php7/conf.d/01_redis.ini \

    && cd /tmp \
    && wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.zip \
    && unzip v${SWOOLE_VERSION}.zip && cd swoole-src-${SWOOLE_VERSION} \
    && /usr/bin/phpize7 && ./configure --enable-openssl --enable-sockets --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=swoole.so >> /etc/php7/conf.d/01_swoole.ini \
    	
	&& cd /tmp \
	&& wget https://github.com/ImageMagick/ImageMagick/archive/7.0.9-19.zip \
	&& unzip 7.0.9-19.zip && cd ImageMagick-7.0.9-19 \
	&& ./configure --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=yes --with-jpeg=yes --with-jp2=yes --with-png=yes --with-tiff=yes && make clean && make && make install && \
	make clean && ldconfig /usr/local/lib
	
	&& cd /tmp \
	&& wget https://github.com/Imagick/imagick/archive/3.4.4.zip \
	&& unzip 3.4.4.zip && cd imagick-3.4.4 \
	&& /usr/bin/phpize7 && ./configure  --with-php-config=/usr/local/bin/php-config7 --with-imagick=/usr/local/lib \
	&& make && make install \
	&& echo extension=imagick.so >> /etc/php7/conf.d/01_imagick.ini \
	
	&& apk del openssl-dev php7-dev autoconf make pkgconf g++ gcc build-base \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && php -m && php --ri swoole

RUN apk --no-cache add bash

COPY --from=composer /ppm /ppm

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
