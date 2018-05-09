FROM ubuntu:12.04

ENV BUILD_DIR=/tmp/build
RUN mkdir -p $BUILD_DIR/test
COPY Makefile.transform360.patch           $BUILD_DIR/
COPY allfilters.c.transform360.patch       $BUILD_DIR/
# in Ubuntu 12.04, the libenca-dev package is missing the archive, since we need static linkage we copy it over
COPY libenca.a /usr/lib/x86_64-linux-gnu/libenca.a
COPY build.sh $BUILD_DIR
COPY env.rc $BUILD_DIR
# for testing VMAF
COPY test/big_buck.mp4 $BUILD_DIR/test/

RUN $BUILD_DIR/build.sh
