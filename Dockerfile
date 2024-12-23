FROM alpine:3.18
MAINTAINER Dan Bryant (daniel.bryant@linux.com)

# add variable VERSION for 7zip build number, The default value here is 2409
ARG VERSION=2409
ENV TZ=Europe/London

# install all the Linux build dependencies
# after clang-14 we get errors
RUN apk add --no-cache alpine-sdk git patch wget clang14 make build-base musl-dev
RUN apk add --no-cache clang14-dev gcc lld
RUN apk add --no-cache llvm14 curl libarchive-tools xz

# create convenience symlinks for clang
RUN ln -s /usr/bin/clang-14 /usr/local/bin/clang
RUN ln -s /usr/bin/clang++-14 /usr/local/bin/clang++

# we will try to compile UASM on Linux
RUN mkdir /usr/local/src && cd /usr/local/src && git clone --branch v2.57r https://github.com/Terraspace/UASM.git
RUN cd /usr/local/src/UASM && make CC="clang -fcommon -static -std=gnu99 -Wno-error=int-conversion" -f Makefile-Linux-GCC-64.mak
RUN cp /usr/local/src/UASM/GccUnixR/uasm /usr/local/bin/uasm

# 7-zip source is now available in Tar XZ format
RUN curl -o /tmp/7z${VERSION}-src.tar.xz "https://www.7-zip.org/a/7z${VERSION}-src.tar.xz"
RUN mkdir /usr/local/src/7z${VERSION} && cd /usr/local/src/7z${VERSION} && tar -xf /tmp/7z${VERSION}-src.tar.xz
RUN rm -f /tmp/7z${VERSION}-src.tar.xz

# MUSL doesn't support pthread_attr_setaffinity_np so we have to disable affinity
# we also have to amend the warnings so we don't trip over "disabled expansion of recursive macro"
# we need a small patch to ensure UASM doesn't try to align the stack in any assembler functions - this mimics expected asmc behaviour
RUN cd /usr/local/src/7z${VERSION} && sed -i -e '1i\OPTION FRAMEPRESERVEFLAGS:ON\nOPTION PROLOGUE:NONE\nOPTION EPILOGUE:NONE' Asm/x86/7zAsm.asm

# create the Clang version
RUN cd /usr/local/src/7z${VERSION}/CPP/7zip/Bundles/Alone2 && make CFLAGS_BASE_LIST="-c -static -D_7ZIP_AFFINITY_DISABLE=1 -DZ7_AFFINITY_DISABLE=1 -D_GNU_SOURCE=1" MY_ASM=uasm MY_ARCH="-static" CFLAGS_WARN_WALL="-Wall -Wextra" -f ../../cmpl_clang_x64.mak
RUN strip /usr/local/src/7z${VERSION}/CPP/7zip/Bundles/Alone2/b/c_x64/7zz
RUN mv /usr/local/src/7z${VERSION}/CPP/7zip/Bundles/Alone2/b/c_x64/7zz /usr/local/bin/7zz
RUN cp /usr/local/bin/7zz /opt/7zz

# clean up the source files for our binaries
RUN rm -rf /usr/local/src/UASM
RUN rm -rf /usr/local/src/7z${VERSION}
