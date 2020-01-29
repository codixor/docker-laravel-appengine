FROM composer:1.9 as composer

RUN mkdir /ppm && cd /ppm && composer require php-pm/php-pm

FROM alpine:3.8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "UTC" | tee /etc/timezone && \
    apk del tzdata

RUN apk --no-cache add supervisor \
    php7 php7-opcache php7-fpm php7-cgi php7-ctype php7-json php7-dom php7-zip php7-zip php7-gd \
    php7-curl php7-mbstring php7-pecl-redis php7-mcrypt php7-bcmath php7-iconv php7-posix \
	php7-pdo_mysql php7-tokenizer php7-simplexml php7-session php7-exif php7-pcntl php7-zlib \
    php7-xml php7-sockets php7-openssl php7-fileinfo php7-ldap php7-xmlwriter php7-phar \
    php7-intl php7-pecl-swoole php7-pecl-imagick
	
ADD etc/php.ini /etc/php7/php.ini

RUN apk --no-cache add bash

COPY --from=composer /ppm /ppm

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
