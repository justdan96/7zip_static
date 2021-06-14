FROM alpine:latest
MAINTAINER Dan Bryant (daniel.bryant@linux.com)

ENV TZ=Europe/London

# install all the Linux build dependencies
RUN apk add --no-cache alpine-sdk git patch wget clang make build-base musl-dev
RUN apk add --no-cache clang-dev gcc lld
RUN apk add --no-cache llvm curl libarchive-tools

# we will try to compile UASM on Linux
RUN mkdir /usr/local/src && cd /usr/local/src && git clone --branch v2.52 https://github.com/Terraspace/UASM.git
COPY dbgcv.patch /usr/local/src/UASM/dbgcv.patch
RUN cd /usr/local/src/UASM && patch < dbgcv.patch
RUN sed -i.bak 's!#ifndef _TYPES_H_INCLUDED!#ifndef _TYPES_H_INCLUDED_!g' /usr/local/src/UASM/H/types.h
RUN cd /usr/local/src/UASM && CFLAGS="-std=c99 -static" make CC=clang -f gccLinux64.mak
RUN cp /usr/local/src/UASM/GccUnixR/uasm /usr/local/bin/uasm

# we need to install 7zip to compile 7zip? As per jo620kix's suggestion we can use bsdtar instead
RUN curl -o /tmp/7z2102-src.7z "https://7-zip.org/a/7z2102-src.7z"
RUN mkdir /usr/local/src/7z2102 && cd /usr/local/src/7z2102 && bsdtar -xf /tmp/7z2102-src.7z
RUN rm -f /tmp/7z2102-src.7z

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
