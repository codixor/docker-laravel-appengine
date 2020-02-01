FROM        alpine:3.8 AS base
RUN     apk  add --no-cache --update libgcc libstdc++ ca-certificates libcrypto1.0 libssl1.0 libgomp expat git
FROM        base AS build
WORKDIR     /tmp/workdir
ARG        PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
ARG        LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG        PREFIX=/opt/ffmpeg
ARG        MAKEFLAGS="-j2"

ENV         FFMPEG_VERSION=4.2.2 \
            AOM_VERSION=v1.0.0 \
            FDKAAC_VERSION=0.1.5 \
            FONTCONFIG_VERSION=2.12.4 \
            FREETYPE_VERSION=2.5.5 \
            FRIBIDI_VERSION=0.19.7 \
            KVAZAAR_VERSION=1.2.0 \
            LAME_VERSION=3.100 \
            LIBASS_VERSION=0.13.7 \
            LIBPTHREAD_STUBS_VERSION=0.4 \
            LIBVIDSTAB_VERSION=1.1.0 \
            LIBXCB_VERSION=1.13.1 \
            XCBPROTO_VERSION=1.13 \
            OGG_VERSION=1.3.2 \
            OPENCOREAMR_VERSION=0.1.5 \
            OPUS_VERSION=1.2 \
            OPENJPEG_VERSION=2.1.2 \
            THEORA_VERSION=1.1.1 \
            VORBIS_VERSION=1.3.5 \
            VPX_VERSION=1.8.0 \
            WEBP_VERSION=1.0.2 \
            X264_VERSION=20170226-2245-stable \
            X265_VERSION=3.1.1 \
            XAU_VERSION=1.0.9 \
            XORG_MACROS_VERSION=1.19.2 \
            XPROTO_VERSION=7.0.31 \
            XVID_VERSION=1.3.4 \
            LIBXML2_VERSION=2.9.10 \
            LIBBLURAY_VERSION=1.1.2 \
            SRC=/usr/local

ARG         FREETYPE_SHA256SUM="5d03dd76c2171a7601e9ce10551d52d4471cf92cd205948e60289251daddffa8 freetype-2.5.5.tar.gz"
ARG         FRIBIDI_SHA256SUM="3fc96fa9473bd31dcb5500bdf1aa78b337ba13eb8c301e7c28923fea982453a8 0.19.7.tar.gz"
ARG         LIBASS_SHA256SUM="8fadf294bf701300d4605e6f1d92929304187fca4b8d8a47889315526adbafd7 0.13.7.tar.gz"
ARG         LIBVIDSTAB_SHA256SUM="14d2a053e56edad4f397be0cb3ef8eb1ec3150404ce99a426c4eb641861dc0bb v1.1.0.tar.gz"
ARG         OGG_SHA256SUM="e19ee34711d7af328cb26287f4137e70630e7261b17cbe3cd41011d73a654692 libogg-1.3.2.tar.gz"
ARG         OPUS_SHA256SUM="77db45a87b51578fbc49555ef1b10926179861d854eb2613207dc79d9ec0a9a9 opus-1.2.tar.gz"
ARG         THEORA_SHA256SUM="40952956c47811928d1e7922cda3bc1f427eb75680c3c37249c91e949054916b libtheora-1.1.1.tar.gz"
ARG         VORBIS_SHA256SUM="6efbcecdd3e5dfbf090341b485da9d176eb250d893e3eb378c428a2db38301ce libvorbis-1.3.5.tar.gz"
ARG         XVID_SHA256SUM="4e9fd62728885855bc5007fe1be58df42e5e274497591fec37249e1052ae316f xvidcore-1.3.4.tar.gz"
ARG         LIBXML2_SHA256SUM="f07dab13bf42d2b8db80620cce7419b3b87827cc937c8bb20fe13b8571ee9501  libxml2-v2.9.10.tar.gz"
ARG         LIBBLURAY_SHA256SUM="a3dd452239b100dc9da0d01b30e1692693e2a332a7d29917bf84bb10ea7c0b42 libbluray-1.1.2.tar.bz2"



RUN     buildDeps="autoconf \
                   automake \
                   bash \
                   binutils \
                   bzip2 \
                   cmake \
                   curl \
                   coreutils \
                   diffutils \
                   file \
                   g++ \
                   gcc \
                   gperf \
                   libtool \
                   make \
                   python \
                   openssl-dev \
                   tar \
                   yasm \
                   nasm \
                   zlib-dev \
                   expat-dev" && \
        apk  add --no-cache --update ${buildDeps}
## opencore-amr https://sourceforge.net/projects/opencore-amr/
RUN \
        DIR=/tmp/opencore-amr && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://versaweb.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-shared  && \
        make && \
        make install && \
        rm -rf ${DIR}
## x264 http://www.videolan.org/developers/x264.html
RUN \
        DIR=/tmp/x264 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
        tar -jx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli && \
        make && \
        make install && \
        rm -rf ${DIR}
### x265 http://x265.org/
RUN \
        DIR=/tmp/x265 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
        tar -zx && \
        cd x265_${X265_VERSION}/build/linux && \
        sed -i "/-DEXTRA_LIB/ s/$/ -DCMAKE_INSTALL_PREFIX=\${PREFIX}/" multilib.sh && \
        sed -i "/^cmake/ s/$/ -DENABLE_CLI=OFF/" multilib.sh && \
        ./multilib.sh && \
        make -C 8bit install && \
        rm -rf ${DIR}
### libogg https://www.xiph.org/ogg/
RUN \
        DIR=/tmp/ogg && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/ogg/libogg-${OGG_VERSION}.tar.gz && \
        echo ${OGG_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libogg-${OGG_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --enable-shared  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libopus https://www.opus-codec.org/
RUN \
        DIR=/tmp/opus && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://archive.mozilla.org/pub/opus/opus-${OPUS_VERSION}.tar.gz && \
        echo ${OPUS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f opus-${OPUS_VERSION}.tar.gz && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
### libvorbis https://xiph.org/vorbis/
RUN \
        DIR=/tmp/vorbis && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz && \
        echo ${VORBIS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libvorbis-${VORBIS_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --with-ogg="${PREFIX}" --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
### libtheora http://www.theora.org/
RUN \
        DIR=/tmp/theora && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/theora/libtheora-${THEORA_VERSION}.tar.gz && \
        echo ${THEORA_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libtheora-${THEORA_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --with-ogg="${PREFIX}" --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
### libvpx https://www.webmproject.org/code/
RUN \
        DIR=/tmp/vpx && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://codeload.github.com/webmproject/libvpx/tar.gz/v${VPX_VERSION} | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-vp8 --enable-vp9 --enable-vp9-highbitdepth --enable-pic --enable-shared \
        --disable-debug --disable-examples --disable-docs --disable-install-bins  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libwebp https://developers.google.com/speed/webp/
RUN \
        DIR=/tmp/vebp && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-shared  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libmp3lame http://lame.sourceforge.net/
RUN \
        DIR=/tmp/lame && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://versaweb.dl.sourceforge.net/project/lame/lame/$(echo ${LAME_VERSION} | sed -e 's/[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)/\1.\2/')/lame-${LAME_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --bindir="${PREFIX}/bin" --enable-shared --enable-nasm --enable-pic --disable-frontend && \
        make && \
        make install && \
        rm -rf ${DIR}
### xvid https://www.xvid.com/
RUN \
        DIR=/tmp/xvid && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xvid.org/downloads/xvidcore-${XVID_VERSION}.tar.gz && \
        echo ${XVID_SHA256SUM} | sha256sum --check && \
        tar -zx -f xvidcore-${XVID_VERSION}.tar.gz && \
        cd xvidcore/build/generic && \
        ./configure --prefix="${PREFIX}" --bindir="${PREFIX}/bin" --datadir="${DIR}" --enable-shared --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
### fdk-aac https://github.com/mstorsjo/fdk-aac
RUN \
        DIR=/tmp/fdk-aac && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}
## openjpeg https://github.com/uclouvain/openjpeg
RUN \
        DIR=/tmp/openjpeg && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        cmake -DBUILD_THIRDPARTY:BOOL=ON -DCMAKE_INSTALL_PREFIX="${PREFIX}" . && \
        make && \
        make install && \
        rm -rf ${DIR}
## freetype https://www.freetype.org/
RUN  \
        DIR=/tmp/freetype && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.gz && \
        echo ${FREETYPE_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f freetype-${FREETYPE_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
## libvstab https://github.com/georgmartius/vid.stab
RUN  \
        DIR=/tmp/vid.stab && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/georgmartius/vid.stab/archive/v${LIBVIDSTAB_VERSION}.tar.gz &&\
        echo ${LIBVIDSTAB_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f v${LIBVIDSTAB_VERSION}.tar.gz && \
        cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" . && \
        make && \
        make install && \
        rm -rf ${DIR}
## fridibi https://www.fribidi.org/
# + https://github.com/fribidi/fribidi/issues/8
RUN  \
        DIR=/tmp/fribidi && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/fribidi/fribidi/archive/${FRIBIDI_VERSION}.tar.gz && \
        echo ${FRIBIDI_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f ${FRIBIDI_VERSION}.tar.gz && \
        sed -i 's/^SUBDIRS =.*/SUBDIRS=gen.tab charset lib/' Makefile.am && \
        ./bootstrap --no-config && \
        ./configure -prefix="${PREFIX}" --disable-static --enable-shared && \
        make -j 1 && \
        make install && \
        rm -rf ${DIR}
## fontconfig https://www.freedesktop.org/wiki/Software/fontconfig/
RUN  \
        DIR=/tmp/fontconfig && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.bz2 &&\
        tar -jx --strip-components=1 -f fontconfig-${FONTCONFIG_VERSION}.tar.bz2 && \
        ./configure -prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
## libass https://github.com/libass/libass
RUN  \
        DIR=/tmp/libass && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/libass/libass/archive/${LIBASS_VERSION}.tar.gz &&\
        echo ${LIBASS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f ${LIBASS_VERSION}.tar.gz && \
        ./autogen.sh && \
        ./configure -prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
## kvazaar https://github.com/ultravideo/kvazaar
RUN \
        DIR=/tmp/kvazaar && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/ultravideo/kvazaar/archive/v${KVAZAAR_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f v${KVAZAAR_VERSION}.tar.gz && \
        ./autogen.sh && \
        ./configure -prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
	DIR=/tmp/aom && \
        git clone --branch ${AOM_VERSION} --depth 1 https://aomedia.googlesource.com/aom ${DIR} ; \
        cd ${DIR} ; \
        rm -rf CMakeCache.txt CMakeFiles ; \
        mkdir -p ./aom_build ; \
        cd ./aom_build ; \
        cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=1 ..; \
        make ; \
        make install ; \
        rm -rf ${DIR}

## libxcb (and supporting libraries) for screen capture https://xcb.freedesktop.org/
RUN \
        DIR=/tmp/xorg-macros && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.x.org/archive//individual/util/util-macros-${XORG_MACROS_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f util-macros-${XORG_MACROS_VERSION}.tar.gz && \
        ./configure -prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/xproto && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.x.org/archive/individual/proto/xproto-${XPROTO_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f xproto-${XPROTO_VERSION}.tar.gz && \
        ./configure -prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libXau && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.x.org/archive/individual/lib/libXau-${XAU_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f libXau-${XAU_VERSION}.tar.gz && \
        ./configure -prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libpthread-stubs && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://xcb.freedesktop.org/dist/libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.gz && \
        PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" ./configure -prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libxcb-proto && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://xcb.freedesktop.org/dist/xcb-proto-${XCBPROTO_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f xcb-proto-${XCBPROTO_VERSION}.tar.gz && \
        ACLOCAL_PATH="${PREFIX}/share/aclocal" ./autogen.sh && \
        PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" ./configure -prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libxcb && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://xcb.freedesktop.org/dist/libxcb-${LIBXCB_VERSION}.tar.gz &&\
        tar -zx --strip-components=1 -f libxcb-${LIBXCB_VERSION}.tar.gz && \
        ACLOCAL_PATH="${PREFIX}/share/aclocal" ./autogen.sh && \
        PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" ./configure -prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

## libxml2 - for libbluray
RUN \
        DIR=/tmp/libxml2 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://gitlab.gnome.org/GNOME/libxml2/-/archive/v${LIBXML2_VERSION}/libxml2-v${LIBXML2_VERSION}.tar.gz && \
        echo ${LIBXML2_SHA256SUM} | sha256sum --check && \
        tar -xz --strip-components=1 -f libxml2-v${LIBXML2_VERSION}.tar.gz && \
        PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" ./configure --prefix="${PREFIX}" --with-ftp=no --with-http=no --with-python=no && \
        make && \
        make install && \
        rm -rf ${DIR}


## libbluray - Requires libxml, freetype, and fontconfig
RUN \
        DIR=/tmp/libbluray && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://download.videolan.org/pub/videolan/libbluray/${LIBBLURAY_VERSION}/libbluray-${LIBBLURAY_VERSION}.tar.bz2 && \
        echo ${LIBBLURAY_SHA256SUM} | sha256sum --check && \
        tar -jx --strip-components=1 -f libbluray-${LIBBLURAY_VERSION}.tar.bz2 && \
        PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" ./configure --prefix="${PREFIX}" --disable-examples --disable-bdjava-jar --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2



RUN \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        ./configure \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --enable-shared \
        --enable-avresample \
        --enable-libopencore-amrnb \
        --enable-libopencore-amrwb \
        --enable-gpl \
        --enable-libass \
        --enable-libfreetype \
        --enable-libvidstab \
        --enable-libmp3lame \
        --enable-libopenjpeg \
        --enable-libopus \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libwebp \
        --enable-libxcb \
        --enable-libx265 \
        --enable-libxvid \
        --enable-libx264 \
        --enable-nonfree \
        --enable-openssl \
        --enable-libfdk_aac \
        --enable-libkvazaar \
        --enable-libaom --extra-libs=-lpthread \
        --enable-postproc \
        --enable-small \
        --enable-version3 \
        --enable-libbluray \
        --extra-cflags="-I${PREFIX}/include" \
        --extra-ldflags="-L${PREFIX}/lib" \
        --extra-libs=-ldl \
        --prefix="${PREFIX}" && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${PREFIX}/bin


RUN \
    LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64:${LD_LIBRARY_PATH}" ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
    cp ${PREFIX}/bin/* /usr/local/bin/ && \
    cp -r ${PREFIX}/share/ffmpeg /usr/local/share/ && \
    LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf
	
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
    PHP_POST_MAX_SIZE="40M" 

ENV NGINX_VERSION 1.17.7
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
        gnu-libiconv imagemagick youtube-dl supervisor
		
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
COPY --from=build /usr/local /usr/local
COPY ppm /usr/bin/ppm
COPY /conf /etc/nginx
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY sysctl.conf /etc/sysctl.conf
COPY php.ini /etc/php7/php.ini

RUN chmod +x /usr/bin/ppm

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
