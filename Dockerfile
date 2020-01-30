FROM composer:1.9 as composer

RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm:2.0.3

FROM alpine:3.8
	
ENV SWOOLE_VERSION=4.4.14

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apk --no-cache add tzdata supervisor && \
    cp /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "UTC" | tee /etc/timezone && \
    apk del tzdata

ENV PHPIZE_DEPS autoconf file g++ gcc libc-dev make pkgconf re2c php7-dev php7-pear \
    libevent-dev openssl-dev imagemagick-dev

RUN apk add --update --no-cache curl wget bash openssl libstdc++ \
        freetype-dev libjpeg-turbo-dev libpng-dev libtool patch pcre-dev imap \
        autoconf build-base linux-headers \
        php7 php7-opcache php7-fpm php7-cgi php7-ctype php7-json php7-dom php7-zip php7-zip php7-gd \
        php7-curl php7-mbstring php7-mcrypt php7-bcmath php7-iconv php7-posix \
        php7-pdo_mysql php7-tokenizer php7-simplexml php7-session php7-exif php7-pcntl php7-zlib \
        php7-xml php7-sockets php7-openssl php7-fileinfo php7-ldap php7-xmlwriter php7-phar \
        php7-intl \
		&& apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
        gnu-libiconv

    && ln -sfv /usr/bin/php7 /usr/bin/php && ln -sfv /usr/bin/php-config7 /usr/bin/php-config && ln -sfv /usr/bin/phpize7 /usr/bin/phpize && ln -sf /usr/sbin/php-fpm7 /usr/bin/php-fpm \
	
    && cd /tmp \
    && wget https://github.com/ImageMagick/ImageMagick/archive/7.0.9-19.zip \
    && unzip 7.0.9-19.zip && cd ImageMagick-7.0.9-19 \
    && ./configure --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=yes --with-jpeg=yes --with-jp2=yes --with-png=yes --with-tiff=yes && make clean && make && make install && \
    make clean && ldconfig /usr/local/lib \
	
    && cd /tmp \
    && wget https://github.com/php/pecl-php-uploadprogress/archive/uploadprogress-1.1.3.zip \
    && unzip uploadprogress-1.1.3.zip && cd pecl-php-uploadprogress-uploadprogress-1.1.3 \
    && /usr/bin/phpize7 && ./configure --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=uploadprogress.so >> /etc/php7/conf.d/01_uploadprogress.ini
	
RUN set -xe \
    && apk add --no-cache --repository "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
    --virtual .phpize-deps \
    $PHPIZE_DEPS \
    && sed -i 's/^exec $PHP -C -n/exec $PHP -C/g' $(which pecl) \
    && pecl channel-update pecl.php.net \    
	&& pecl install imagick \
    && echo "extension=imagick.so" > /etc/php7/conf.d/01_imagick.ini \
	&& pecl install redis \
    && echo "extension=redis.so" > /etc/php7/conf.d/01_redis.ini \
	&& pecl install igbinary \
    && echo "extension=igbinary.so" > /etc/php7/conf.d/01_igbinary.ini \
	&& pecl install swoole \
    && echo "extension=swoole.so" > /etc/php7/conf.d/01_swoole.ini \
    && rm -rf /usr/share/php7 \   
    && apk del .phpize-deps
	
RUN apk del --purge openssl-dev php7-dev php7-pear imagemagick-dev libc-dev freetype-dev libjpeg-turbo-dev libpng-dev libtool patch build-base linux-headers autoconf make pkgconf re2c g++ gcc build-base linux-headers libstdc++ patch pcre-dev imap \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/include/php /root/.composer \    

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN apk --no-cache add bash

COPY --from=composer /ppm /ppm

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
