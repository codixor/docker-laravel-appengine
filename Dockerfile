FROM composer:1.9 as composer

RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm:2.0.3

FROM alpine:3.9
	
ENV SWOOLE_VERSION=4.4.14

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apk --no-cache add tzdata supervisor && \
    cp /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "UTC" | tee /etc/timezone && \
    apk del tzdata

RUN apk add --update --no-cache curl wget bash openssl libstdc++ \
        openssl-dev php7-dev imagemagick-dev libc-dev freetype-dev libjpeg-turbo-dev libpng-dev libtool patch pcre-dev imap \
        autoconf make pkgconf g++ gcc build-base linux-headers \
        php7 php7-opcache php7-fpm php7-cgi php7-ctype php7-json php7-dom php7-zip php7-zip php7-gd \
        php7-curl php7-mbstring php7-mcrypt php7-bcmath php7-iconv php7-posix \
        php7-pdo_mysql php7-tokenizer php7-simplexml php7-session php7-exif php7-pcntl php7-zlib \
        php7-xml php7-sockets php7-openssl php7-fileinfo php7-ldap php7-xmlwriter php7-phar \
        php7-intl \

    && ln -sfv /usr/bin/php7 /usr/bin/php && ln -sfv /usr/bin/php-config7 /usr/bin/php-config && ln -sfv /usr/bin/phpize7 /usr/bin/phpize && ln -sf /usr/sbin/php-fpm7 /usr/bin/php-fpm \
	
    && cd /tmp \
    && wget https://github.com/ImageMagick/ImageMagick/archive/7.0.9-19.zip \
    && unzip 7.0.9-19.zip && cd ImageMagick-7.0.9-19 \
    && ./configure --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=yes --with-jpeg=yes --with-jp2=yes --with-png=yes --with-tiff=yes && make clean && make && make install && \
    make clean && ldconfig /usr/local/lib \
	
    && cd /tmp \
    && wget https://github.com/igbinary/igbinary/archive/3.1.2.zip \
    && unzip 3.1.2.zip && cd igbinary-3.1.2 \
    && /usr/bin/phpize7 && ./configure --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=igbinary.so >> /etc/php7/conf.d/01_igbinary.ini \
	
    && cd /tmp \
    && wget https://github.com/php/pecl-php-uploadprogress/archive/uploadprogress-1.1.3.zip \
    && unzip uploadprogress-1.1.3.zip && cd pecl-php-uploadprogress-uploadprogress-1.1.3 \
    && /usr/bin/phpize7 && ./configure --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=uploadprogress.so >> /etc/php7/conf.d/01_uploadprogress.ini \

    && cd /tmp \
    && wget https://github.com/phpredis/phpredis/archive/5.1.1.zip \
    && unzip 5.1.1.zip && cd phpredis-5.1.1 \
    && /usr/bin/phpize7 && ./configure --enable-redis-igbinary --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=redis.so >> /etc/php7/conf.d/01_redis.ini \

    && cd /tmp \
    && wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.zip \
    && unzip v${SWOOLE_VERSION}.zip && cd swoole-src-${SWOOLE_VERSION} \
    && /usr/bin/phpize7 && ./configure --enable-http2 --enable-mysqlnd --enable-openssl --enable-sockets --with-php-config=/usr/bin/php-config7 \
    && make && make install \
    && echo extension=swoole.so >> /etc/php7/conf.d/01_swoole.ini \
	
    && sed -ie 's/-n//g' /usr/bin/pecl \
    && yes | pecl install imagick \    
    && echo extension=imagick.so >> /etc/php7/conf.d/01_imagick.ini \
	
    && apk del --purge openssl-dev php7-dev imagemagick-dev libc-dev freetype-dev libjpeg-turbo-dev libpng-dev libtool autoconf make pkgconf g++ gcc build-base linux-headers patch pcre-dev imap \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/include/php /root/.composer \    

RUN apk --no-cache add bash

COPY --from=composer /ppm /ppm

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
