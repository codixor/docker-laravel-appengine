FROM composer:1.9 as composer
ARG COMPOSER_FLAGS='--prefer-dist --ignore-platform-reqs --optimize-autoloader'
ENV COMPOSER_FLAGS=${COMPOSER_FLAGS}

RUN mkdir /ppm && cd /ppm && composer ${COMPOSER_FLAGS} require php-pm/php-pm:2.0.3

FROM alpine:3.11

ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="40000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="1024" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10" \
    PHP_UPLOAD_MAX_FILESIZE="40M" \
    PHP_POST_MAX_SIZE="40M" \
    PHP_FPM_LISTEN="127.0.0.1:9000" \
    PHP_FPM_USER="nobody" \     
    PHP_FPM_PM_TYPE="dynamic" \    
    PHP_FPM_PM_MAX_CHILDREN="5" \
    PHP_FPM_PM_START_SERVERS="2" \
    PHP_FPM_MIN_SPARE_SERVERS="1" \
    PHP_FPM_MAX_SPARE_SERVERS="3" \
    PHP_FPM_MAX_REQUESTS="500"    

ENV NGINX_VERSION 1.17.8
ENV LUA_MODULE_VERSION 0.10.13
ENV DEVEL_KIT_MODULE_VERSION 0.3.0
ENV LUAJIT_LIB=/usr/lib
ENV LUAJIT_INC=/usr/include/luajit-2.1
ENV MAXMIND_VERSION=1.4.2
ENV NGX_BROTLI_COMMIT e505dce68acc190cc5a1e780a3b0275e39f160ca
ENV HEADERS_MORE_VERSION=0.33

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "UTC" | tee /etc/timezone && \
    apk del tzdata

ENV PHPIZE_DEPS autoconf file g++ gcc libc-dev make pkgconf re2c php7-dev php7-pear \
    libevent-dev openssl-dev imagemagick-dev freetype-dev libjpeg-turbo-dev libpng-dev pcre-dev 

RUN apk add --no-cache --update --repository http://dl-cdn.alpinelinux.org/alpine/v3.8/community/ --allow-untrusted \
        curl wget bash openssl libstdc++ \
        libtool patch imap build-base linux-headers \
        php7 php7-opcache php7-fpm php7-cgi php7-ctype php7-json php7-dom php7-zip php7-zip php7-gd \
        php7-curl php7-mbstring php7-mcrypt php7-bcmath php7-iconv php7-posix \
        php7-pdo_mysql php7-tokenizer php7-simplexml php7-session php7-exif php7-pcntl php7-zlib \
        php7-xml php7-sockets php7-openssl php7-fileinfo php7-ldap php7-xmlwriter php7-phar \
        php7-intl \
		&& apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
        gnu-libiconv imagemagick youtube-dl supervisor ffmpeg
		
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN ln -sfv /usr/bin/php7 /usr/bin/php && ln -sfv /usr/bin/php-config7 /usr/bin/php-config && ln -sfv /usr/bin/phpize7 /usr/bin/phpize && ln -sf /usr/sbin/php-fpm7 /usr/bin/php-fpm  
	
RUN set -xe \
    && apk add --no-cache --repository "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
    --virtual .phpize-deps \
    $PHPIZE_DEPS \
    && sed -i 's/^exec $PHP -C -n/exec $PHP -C/g' $(which pecl) \
    && pecl channel-update pecl.php.net \    
	&& pecl install uploadprogress \
    && echo "extension=uploadprogress.so" > /etc/php7/conf.d/01_uploadprogress.ini \
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
	
RUN apk del --purge libtool build-base linux-headers libstdc++ patch imap \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/include/php /root/.composer

RUN ldconfig || :

RUN GPG_KEYS=a \
	&& CONFIG="\
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--user=nginx \
		--group=nginx \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module=dynamic \
		--with-http_image_filter_module=dynamic \
		--with-http_geoip_module=dynamic \
		--with-http_perl_module=dynamic \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-http_slice_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-file-aio \
		--with-http_v2_module \
		--with-ipv6 \
		--add-dynamic-module=/ngx_http_geoip2_module \
		--add-module=/usr/src/ngx_devel_kit-$DEVEL_KIT_MODULE_VERSION \
    	--add-module=/usr/src/lua-nginx-module-$LUA_MODULE_VERSION \
    	--add-module=/usr/src/ngx_brotli \
    	--add-module=/usr/src/headers-more-nginx-module-$HEADERS_MORE_VERSION \
		--add-dynamic-module=/usr/src/ModSecurity-nginx \
        --with-cc-opt=-Wno-error \
	" \
	&& addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	\
	&& set -x \
	&& apk add --no-cache --virtual .build-deps alpine-sdk perl \
	&& git clone https://github.com/leev/ngx_http_geoip2_module /ngx_http_geoip2_module \
	&& wget https://github.com/maxmind/libmaxminddb/releases/download/${MAXMIND_VERSION}/libmaxminddb-${MAXMIND_VERSION}.tar.gz \
	&& tar xf libmaxminddb-${MAXMIND_VERSION}.tar.gz \
	&& cd libmaxminddb-${MAXMIND_VERSION} \
	&& ./configure \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make check \
	&& make install \
	&& apk del .build-deps \
	\
	&& apk add --no-cache tzdata curl wget \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		linux-headers \
		gnupg \
		libxslt-dev \
		gd-dev \
		geoip-dev \
		perl-dev \
		luajit-dev \
	&& apk add --no-cache --virtual .modsec-build-deps \
		libxml2-dev \
		flex \
		bison \
		yajl-dev \
		file \
	&& apk add --no-cache --virtual .brotli-build-deps \
		autoconf \
		libtool \
		automake \
		git \
		g++ \
		cmake \
	&& mkdir -p /usr/src \
	\
	&& cd /usr/src \
	&& git clone --recursive https://github.com/google/ngx_brotli.git \
	&& cd ngx_brotli \
	&& git checkout -b $NGX_BROTLI_COMMIT $NGX_BROTLI_COMMIT \
	&& cd .. \
	\
	####################### Add ModSecurity module
	\
	&& cd /usr/src \
	&& git clone --depth 1 --single-branch https://github.com/SpiderLabs/ModSecurity \
	&& cd ModSecurity \
	&& git submodule init \
	&& git submodule update \
	&& ./build.sh \
	&& ./configure \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -fR /usr/src/ModSecurity \
	\
	&& cd /usr/src \
	&& git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git \
	&& mkdir -p /etc/nginx/modsec \
	&& wget -qc -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
	&& mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf \
	&& sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf \
	\
	&& cd /usr/src \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
	&& curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v$DEVEL_KIT_MODULE_VERSION.tar.gz -o ndk.tar.gz \
  	&& curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$LUA_MODULE_VERSION.tar.gz -o lua.tar.gz \
	&& curl -fSL https://github.com/openresty/headers-more-nginx-module/archive/v$HEADERS_MORE_VERSION.tar.gz -o headers-more-nginx-module-$HEADERS_MORE_MODULE_PATH.tar.gz \
	&& sha512sum nginx.tar.gz nginx.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& tar -zxC /usr/src -f ndk.tar.gz \
	&& tar -zxC /usr/src -f lua.tar.gz \
	&& tar -zxC /usr/src -f headers-more-nginx-module-$HEADERS_MORE_MODULE_PATH.tar.gz \
	&& rm nginx.tar.gz ndk.tar.gz lua.tar.gz headers-more-nginx-module-$HEADERS_MORE_MODULE_PATH.tar.gz \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
	&& mv objs/ngx_http_perl_module.so objs/ngx_http_perl_module-debug.so \
	&& ./configure $CONFIG \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
	&& install -m755 objs/ngx_http_perl_module-debug.so /usr/lib/nginx/modules/ngx_http_perl_module-debug.so \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& rm -rf /usr/src/nginx-$NGINX_VERSION \
	&& rm -rf /usr/src/ngx_brotli \
	\
    # Install mime types and other files
    && cd /usr/src \
    && curl -fSL https://raw.githubusercontent.com/nginx/nginx/master/conf/mime.types -o mime.types \
    && curl -fSL https://raw.githubusercontent.com/nginx/nginx/master/conf/fastcgi_params -o fastcgi_params \
    && curl -fSL https://gist.githubusercontent.com/romanoffs/29b981cccff51b0ea564e258e1ed2e85/raw/17bdc5b7c940604d84a9481fe28010d7b93ab043/cloudflare.conf -o cloudflare.conf \	
    && mv /usr/src/mime.types /etc/nginx/ \
	&& mv /usr/src/fastcgi_params /etc/nginx/ \
	&& mv /usr/src/cloudflare.conf /etc/nginx/ \
	\
	# Bring in gettext so we can get `envsubst`, then throw
	# the rest away. To do this, we need to install `gettext`
	# then move `envsubst` out of the way so `gettext` can
	# be deleted completely, then move `envsubst` back.
	&& apk add --no-cache --virtual .gettext gettext \
	&& mv /usr/bin/envsubst /tmp/ \
	\
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --no-cache --virtual .nginx-rundeps $runDeps \
	&& apk del .build-deps \
	&& apk del .brotli-build-deps \
	&& apk del .gettext \
	&& mv /tmp/envsubst /usr/local/bin/ \
	\
	&& rm -fR /usr/src/ModSecurity-nginx \
	\
	# forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
	
RUN apk del .modsec-build-deps
RUN rm -fR /libmaxminddb-1.4.2.tar.gz
RUN rm -fR /libmaxminddb-1.4.2
RUN rm -fR /ngx_http_geoip2_module
RUN rm -fR /usr/src/*
    
COPY --from=composer /ppm /ppm
COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY ppm /usr/bin/ppm
COPY /conf /etc/nginx
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY sysctl.conf /etc/sysctl.conf
COPY php.ini /etc/php7/php.ini
COPY www.conf /etc/php7/php-fpm.d/www.conf

RUN chmod +x /usr/bin/ppm


# Setup document root
RUN mkdir -p /var/www/html \
    && mkdir -p /var/lib/nginx \
	&& mkdir -p /var/tmp/nginx

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/tmp/nginx && \
  chown -R nobody.nobody /var/log/php7 && \
  chown -R nobody.nobody /var/log/nginx

# Make the document root a volume
VOLUME /var/www/html

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
