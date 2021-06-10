FROM alpine:latest
MAINTAINER Dan Bryant (daniel.bryant@linux.com)

ENV TZ=Europe/London

# install all the Linux build dependencies
RUN apk add --no-cache alpine-sdk git patch wget clang make cmake build-base musl-dev
RUN apk add --no-cache clang-dev gcc lld dpkg zip
RUN apk add --no-cache zlib-static zlib-dev freetype-static freetype-dev bzip2-static bzip2-dev
RUN apk add --no-cache libpng-static libpng-dev brotli-static brotli-dev brotli-libs
RUN apk add --no-cache harfbuzz-static icu-static graphite2-static
RUN apk add --no-cache pcre2-dev libxcb-static libxcb-dev libxrender-dev cups-dev mesa-dev
RUN apk add --no-cache llvm curl

# ensure only Clang is used, not GCC
RUN ln -sf /usr/bin/clang /usr/bin/cc
RUN ln -sf /usr/bin/clang++ /usr/bin/c++

RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang 10
RUN update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 10
RUN update-alternatives --install /usr/bin/ld ld /usr/bin/lld 10

RUN update-alternatives --auto cc
RUN update-alternatives --auto c++
RUN update-alternatives --auto ld

# brotli-static installs with a suffix, we need to work around that
RUN ln -sf /usr/lib/libbrotlicommon-static.a /usr/lib/libbrotlicommon.a
RUN ln -sf /usr/lib/libbrotlidec-static.a /usr/lib/libbrotlidec.a
RUN ln -sf /usr/lib/libbrotlienc-static.a /usr/lib/libbrotlienc.a

# required for QML to build correctly
RUN ln -sf /usr/bin/python3 /usr/bin/python

# setup openSSL static and a few other dependencies
RUN apk add --no-cache perl xz openssl-libs-static openssl-dev \
	glib-static gettext-static 
RUN apk add --no-cache meson m4 autoconf libtool

# we will try to compile UASM on Linux
RUN mkdir /usr/local/src && cd /usr/local/src && git clone --branch v2.53 https://github.com/Terraspace/UASM.git
COPY dbgcv.patch /usr/local/src/UASM/dbgcv.patch
RUN cd /usr/local/src/UASM && patch < dbgcv.patch
RUN sed -i.bak 's!#ifndef _TYPES_H_INCLUDED!#ifndef _TYPES_H_INCLUDED_!g' /usr/local/src/UASM/H/types.h
RUN sed -i.bak 's/^inline//g' /usr/local/src/UASM/H/picohash.h
RUN sed -i.bak 's/^static inline//g' /usr/local/src/UASM/H/picohash.h
RUN cd /usr/local/src/UASM && CFLAGS="-std=c99 -static" make CC=clang -f gccLinux64.mak
RUN cp /usr/local/src/UASM/GccUnixR/uasm /usr/local/bin/uasm

# we need to install 7zip to compile 7zip? I've created a tar GZ archive instead
RUN curl -o /tmp/7z2102-src.tar.gz "https://justdan96-public.s3.eu.cloud-object-storage.appdomain.cloud/7z2102-src.tar.gz"
RUN mkdir /usr/local/src/7z2102 && cd /usr/local/src/7z2102 && tar -xf /tmp/7z2102-src.tar.gz
RUN rm -f /tmp/7z2102-src.tar.gz

# MUSL doesn't support pthread_attr_setaffinity_np so we have to disable affinity
# we also have to amend the warnings so we don't trip over "disabled expansion of recursive macro"

# create the Clang version
RUN cd /usr/local/src/7z2102/CPP/7zip/Bundles/Alone2 && make CFLAGS_BASE_LIST="-c -static -D_7ZIP_AFFINITY_DISABLE=1" MY_ASM=uasm MY_ARCH="-static" CFLAGS_WARN_WALL="-Wall -Wextra" -f ../../cmpl_clang_x64.mak
RUN mv /usr/local/src/7z2102/CPP/7zip/Bundles/Alone2/b/c_x64/7zz /usr/local/bin/7zz_clang
RUN cd /usr/local/src/7z2102/CPP/7zip/Bundles/Alone2 && make CFLAGS_BASE_LIST="-c -static -D_7ZIP_AFFINITY_DISABLE=1" MY_ASM=uasm MY_ARCH="-static" CFLAGS_WARN_WALL="-Wall -Wextra" -f ../../cmpl_clang_x64.mak clean

# create the GCC version
RUN cd /usr/local/src/7z2102/CPP/7zip/Bundles/Alone2 && make CFLAGS_BASE_LIST="-c -static -D_7ZIP_AFFINITY_DISABLE=1" MY_ASM=uasm MY_ARCH="-no-pie -static" CFLAGS_WARN_WALL="-Wall -Wextra" -f ../../cmpl_gcc_x64.mak
RUN mv /usr/local/src/7z2102/CPP/7zip/Bundles/Alone2/b/g_x64/7zz /usr/local/bin/7zz_gcc
RUN cd /usr/local/src/7z2102/CPP/7zip/Bundles/Alone2 && make CFLAGS_BASE_LIST="-c -static -D_7ZIP_AFFINITY_DISABLE=1" MY_ASM=uasm MY_ARCH="-no-pie -static" CFLAGS_WARN_WALL="-Wall -Wextra" -f ../../cmpl_gcc_x64.mak clean

# clean up the source files for our binaries
RUN rm -rf /usr/local/src/UASM
RUN rm -rf /usr/local/src/7z2102
