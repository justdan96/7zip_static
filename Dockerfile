# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.23.4
MAINTAINER Dan Bryant (daniel.bryant@linux.com)

# bump: 7zip /VERSION=(\d+)/ git:https://github.com/ip7z/7zip.git|*|re:/\.//
ARG VERSION=2601
ENV TZ=Europe/London

# install all the Linux build dependencies
# after clang-14 we get errors
RUN apk add --no-cache alpine-sdk git patch wget clang16 make build-base musl-dev
RUN apk add --no-cache clang16-dev gcc lld
RUN apk add --no-cache llvm16 curl libarchive-tools xz

# create convenience symlinks for clang
RUN ln -s /usr/bin/clang-16 /usr/local/bin/clang
RUN ln -s /usr/bin/clang++-16 /usr/local/bin/clang++

# bump: asmc /ASMC_VERSION=([\d.]+)/ git:https://github.com/nidud/asmc.git|v*
ARG ASMC_VERSION=2.38
RUN mkdir -p /usr/local/src
RUN curl -o /tmp/asmc-${ASMC_VERSION}.zip -k -L "https://github.com/nidud/asmc/releases/download/v${ASMC_VERSION}/asmc-${ASMC_VERSION}Lin64.zip"
RUN unzip /tmp/asmc-${ASMC_VERSION}.zip -d /usr/local/src/asmc-${ASMC_VERSION}
RUN chmod +x /usr/local/src/asmc-${ASMC_VERSION}/asmc-${ASMC_VERSION}/bin/asmc*
RUN cp /usr/local/src/asmc-${ASMC_VERSION}/asmc-${ASMC_VERSION}/bin/asmc* /usr/local/bin/
RUN rm -f /tmp/asmc-${ASMC_VERSION}.zip

# 7-zip source is now available in Tar XZ format
RUN curl -o /tmp/7z${VERSION}-src.tar.xz "https://www.7-zip.org/a/7z${VERSION}-src.tar.xz"
RUN mkdir /usr/local/src/7z${VERSION} && cd /usr/local/src/7z${VERSION} && tar -xf /tmp/7z${VERSION}-src.tar.xz
RUN rm -f /tmp/7z${VERSION}-src.tar.xz

# MUSL doesn't support pthread_attr_setaffinity_np so we have to disable affinity
# we also have to amend the warnings so we don't trip over "disabled expansion of recursive macro"
RUN cd /usr/local/src/7z${VERSION}/CPP/7zip/Bundles/Alone2 && make CFLAGS_BASE_LIST="-c -static -D_7ZIP_AFFINITY_DISABLE=1 -DZ7_AFFINITY_DISABLE=1 -D_GNU_SOURCE=1" MY_ASM=asmc64 MY_ARCH="-static" CFLAGS_WARN_WALL="-Wall -Wextra" -f ../../cmpl_clang_x64.mak
RUN strip /usr/local/src/7z${VERSION}/CPP/7zip/Bundles/Alone2/b/c_x64/7zz
RUN mv /usr/local/src/7z${VERSION}/CPP/7zip/Bundles/Alone2/b/c_x64/7zz /usr/local/bin/7zz
RUN cp /usr/local/bin/7zz /opt/7zz

# clean up the source files for our binaries
RUN rm -rf /usr/local/src/UASM
RUN rm -rf /usr/local/src/7z${VERSION}
