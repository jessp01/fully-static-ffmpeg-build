FROM ubuntu:12.04

# g++ 4.8 or above is required since c11 support is needed for several deps 
ENV G_PLUS_PLUS_VER 4.9 
# nasm 2.13 or above is required
ENV NASM_VER 2.13.02
# cmake 2.8.10 or above is required
ENV CMAKE_VER 2.8.12.2
ENV X264_VER 20180424-2245
ENV X265_VER 2.7
ENV FDK_ACC_VER 0.1.6
ENV LAME_VER 3.99.5
ENV OGG_VER 1.3.3
ENV LIBVORBIS_VER 1.3.5
ENV LIBTHEORA_VER 1.1.1
ENV SPEEX_VER 1.2.0
ENV XVIDCORE_VER 1.3.5
ENV OPENCORE_AMR_VER 0.1.5
ENV OPENJPEG_VER 2.3.0
ENV LIBVPX_VER 1.7.0
# sadly, the last tag created here is rather old so we're forced to go with master
ENV VMAF_VER master
# sadly, this repo has no tags or branches so we're forced to go with master
ENV TRANSFORM360_VER master
ENV OPENCV_VER 2.4.13.6
ENV FFMPEG_VER 4.0
ENV FFMPEG_PREFIX /opt/kaltura/ffmpeg-$FFMPEG_VER
ENV BUILD_DIR /tmp/build
ENV MAKE_PARALLEL_JOBS 4

RUN mkdir -p $BUILD_DIR
COPY vf_transform360.c  $BUILD_DIR/
COPY Makefile.transform360.patch           $BUILD_DIR/
COPY allfilters.c.transform360.patch       $BUILD_DIR/
# in Ubuntu 12.04, the libenca-dev package is missing the archive, since we need static linkage we copy it over
COPY libenca.a /usr/lib/x86_64-linux-gnu/libenca.a

RUN apt-get update -qq && \
        apt-get install software-properties-common python-software-properties -y && \
        add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
        apt-get update 

RUN apt-get install -y \
        g++-$G_PLUS_PLUS_VER \
	libopencv-dev \
        bzip2 \
        unzip \
        wget \
	patch \
        build-essential \
        autoconf \
        automake \
        libass-dev \
        libfreetype6-dev \
        libtheora-dev \
        libtool \
        libva-dev \
        libvorbis-dev \
        libxcb1-dev \
        libxcb-shm0-dev \
        libxcb-xfixes0-dev \
        zlib1g-dev  \
        libgsm1-dev \
        libhdf5-serial-dev \
        libfreetype6-dev \
        liblapack-dev \
        python \
        python-setuptools \
        python-dev \
        python-pip \
        python-tk && \
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$G_PLUS_PLUS_VER 60 --slave /usr/bin/g++ g++ /usr/bin/g++-$G_PLUS_PLUS_VER 

# nasm 2.13 or above is required and since the Ubuntu 12.04 repos have an older version, we must build our own
RUN mkdir -p /usr/local/lib/pkgconfig && \
        cd $BUILD_DIR  && \
        wget -q http://www.nasm.us/pub/nasm/releasebuilds/$NASM_VER/nasm-$NASM_VER.tar.bz2 && \
        tar jxf nasm-$NASM_VER.tar.bz2 && \
        cd nasm-$NASM_VER && \
        ./autogen.sh && \
        ./configure  && make && make install 

# cmake 2.8.10 or above is required
RUN cd $BUILD_DIR && wget -q http://www.cmake.org/files/v2.8/cmake-$CMAKE_VER.tar.gz && \
        tar xzf cmake-$CMAKE_VER.tar.gz && \
        cd cmake-$CMAKE_VER && \
        ./configure && \
        make -j$MAKE_PARALLEL_JOBS && \
        make install && cd $BUILD_DIR

RUN cd $BUILD_DIR && wget -q ftp://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-$X264_VER-stable.tar.bz2 && \
        tar jxf x264-snapshot-$X264_VER-stable.tar.bz2 && \
        cd x264-snapshot-$X264_VER-stable && \
        ./configure && make -j$MAKE_PARALLEL_JOBS && make install
# copy headers and libx264.a, you'd expect the `install` target to do that but it doesn't
RUN cp $BUILD_DIR/x264-snapshot-$X264_VER-stable/libx264.a /usr/local/lib && \
        cp $BUILD_DIR/x264-snapshot-$X264_VER-stable/x264_config.h $BUILD_DIR/x264-snapshot-$X264_VER-stable/x264.h /usr/local/include 

RUN cd $BUILD_DIR && wget -q https://bitbucket.org/multicoreware/x265/downloads/x265_$X265_VER.tar.gz && \
        tar zxf x265_$X265_VER.tar.gz && \
        cd x265_$X265_VER/build/linux && \
        cmake ../../source && \
        ./multilib.sh && \
        cp ./8bit/libx265.a /usr/local/lib/libx265.a && \
        cp ./8bit/x265.pc /usr/local/lib/pkgconfig/ && \
        cp ./8bit/x265_config.h /usr/local/include/ && \
        cp $BUILD_DIR/x265_$X265_VER/source/x265.h /usr/local/include 

RUN cd $BUILD_DIR && wget -q https://github.com/mstorsjo/fdk-aac/archive/v$FDK_ACC_VER.tar.gz -O fdk-aac-v$FDK_ACC_VER.tar.gz && \
        tar zxf fdk-aac-v$FDK_ACC_VER.tar.gz && \
        cd fdk-aac-$FDK_ACC_VER && \
        ./autogen.sh && \
        ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install 

RUN cd $BUILD_DIR && wget -q http://sourceforge.net/projects/lame/files/lame/3.99/lame-$LAME_VER.tar.gz \
        && tar zxf lame-$LAME_VER.tar.gz \
        && cd lame-$LAME_VER \
        && ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install

RUN cd $BUILD_DIR && wget -q http://downloads.xiph.org/releases/ogg/libogg-$OGG_VER.tar.gz && \
        tar zxf libogg-$OGG_VER.tar.gz && \
        cd libogg-$OGG_VER && \
        ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install

RUN cd $BUILD_DIR && wget -q http://downloads.xiph.org/releases/vorbis/libvorbis-$LIBVORBIS_VER.tar.gz && \
        tar zxf libvorbis-$LIBVORBIS_VER.tar.gz  && \
        cd libvorbis-$LIBVORBIS_VER && \
        ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install 

RUN cd $BUILD_DIR && wget -q http://downloads.xiph.org/releases/theora/libtheora-$LIBTHEORA_VER.tar.gz && \
        tar zxf libtheora-$LIBTHEORA_VER.tar.gz  && \
        cd libtheora-$LIBTHEORA_VER && \
        ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install 

RUN cd $BUILD_DIR && wget -q http://downloads.xiph.org/releases/speex/speex-$SPEEX_VER.tar.gz && \
        tar zxf speex-$SPEEX_VER.tar.gz  && \
        cd speex-$SPEEX_VER && \
        ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install 

RUN cd $BUILD_DIR && wget -q http://downloads.xvid.org/downloads/xvidcore-$XVIDCORE_VER.tar.gz && \
        tar zxf xvidcore-$XVIDCORE_VER.tar.gz  && \
        cd xvidcore/build/generic && \
        ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install 

RUN cd $BUILD_DIR && wget -q http://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-$OPENCORE_AMR_VER.tar.gz && \
        tar zxf opencore-amr-$OPENCORE_AMR_VER.tar.gz && \
        cd opencore-amr-$OPENCORE_AMR_VER && \
        ./configure --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install

RUN cd $BUILD_DIR && wget -q https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VER.tar.gz -O openjpeg-v$OPENJPEG_VER.tar.gz && \
        tar zxf openjpeg-v$OPENJPEG_VER.tar.gz && \
        cd openjpeg-$OPENJPEG_VER/ && \
        cmake -G "Unix Makefiles" && \
        make -j$MAKE_PARALLEL_JOBS && make install

RUN cd $BUILD_DIR && wget -q https://github.com/webmproject/libvpx/archive/v$LIBVPX_VER.tar.gz && \
        tar zxf v$LIBVPX_VER.tar.gz && \
        cd libvpx-$LIBVPX_VER/ && \
        ./configure --enable-pic --enable-static --disable-shared && make -j$MAKE_PARALLEL_JOBS && make install 

RUN cd $BUILD_DIR && wget -q https://github.com/Netflix/vmaf/archive/$VMAF_VER.zip -O vmaf-$VMAF_VER.zip && \
        unzip vmaf-$VMAF_VER.zip && \
        cd vmaf-$VMAF_VER && \ 
        make -j$MAKE_PARALLEL_JOBS && make install 

#RUN cd $BUILD_DIR && wget -q https://github.com/opencv/opencv/archive/$OPENCV_VER.tar.gz -O opencv-$OPENCV_VER.tar.gz && \
#        tar zxf opencv-$OPENCV_VER.tar.gz && \
#        cd opencv-$OPENCV_VER && \
#        rm -f CMakeCache.txt && \
#        mkdir buildme && \
#        cd buildme && \
#        cmake $BUILD_DIR/opencv-$OPENCV_VER/ -DCMAKE_BUILD_TYPE=RELEASE -DBUILD_SHARED_LIBS=OFF -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON && \
#        make -j$MAKE_PARALLEL_JOBS && make install

# build ffmpeg with transform360
RUN cd $BUILD_DIR && wget -q http://ffmpeg.org/releases/ffmpeg-$FFMPEG_VER.tar.gz && \
        tar zxf ffmpeg-$FFMPEG_VER.tar.gz && \
        cd ffmpeg-$FFMPEG_VER && \
	wget -q https://github.com/facebook/transform360/archive/$TRANSFORM360_VER.zip -O transform360-$TRANSFORM360_VER.zip && \
        unzip transform360-$TRANSFORM360_VER.zip && \
        cd transform360-$TRANSFORM360_VER/Transform360 && \
        rm -f CMakeCache.txt && \
        cmake . && make -j$MAKE_PARALLEL_JOBS && \
        mkdir -p $BUILD_DIR/objects && \
        cd $BUILD_DIR/objects && \
	dpkg -L libopencv-core-dev && \
        # extract libstdc++ and opencv objects
        #for A in /usr/local/lib/libopencv_*.a;do ar x $A;done && \
        for A in /usr/lib/libopencv_*.a;do ar x $A;done && \
        ar x /usr/lib/gcc/x86_64-linux-gnu/$G_PLUS_PLUS_VER/libstdc++.a && \
	ar x /usr/lib/x86_64-linux-gnu/libm.a && \
        cd $BUILD_DIR/ffmpeg-$FFMPEG_VER/transform360-$TRANSFORM360_VER/Transform360 && \
        rm libTransform360.a && \
        # push all libstdc++ and opencv objects into libTransform360.a [cause fully static linkage is required]
        ar cr libTransform360.a  CMakeFiles/Transform360.dir/Library/VideoFrameTransform.cpp.o CMakeFiles/Transform360.dir/Library/VideoFrameTransformHandler.cpp.o $BUILD_DIR/objects/*o && \
        make install && cd $BUILD_DIR/ffmpeg-$FFMPEG_VER && \
        cp $BUILD_DIR/vf_transform360.c libavfilter/ && \
	cp $BUILD_DIR/Makefile.transform360.patch libavfilter && patch -p0 < libavfilter/Makefile.transform360.patch && \ 
	cp $BUILD_DIR/allfilters.c.transform360.patch libavfilter && patch -p0 < libavfilter/allfilters.c.transform360.patch && \ 
        ./configure --prefix=$FFMPEG_PREFIX --libdir=$FFMPEG_PREFIX/lib --shlibdir=$FFMPEG_PREFIX/lib --extra-cflags='-static -static-libstdc++ -static-libgcc -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -fPIC' --pkg-config-flags=--static --enable-ffplay --enable-gpl --enable-nonfree --enable-version3 --disable-devices --enable-indev=lavfi --enable-avfilter --enable-filter=movie --enable-postproc --enable-pthreads --enable-swscale --disable-bzlib --enable-libx264 --enable-libx265 --enable-libvpx --enable-libfdk-aac --enable-libmp3lame --enable-libgsm --enable-libtheora --enable-libvorbis --enable-libspeex --enable-libxvid --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-libass --enable-libfreetype --enable-fontconfig --enable-avisynth --disable-autodetect --disable-vdpau --enable-libopencv --extra-libs='-lm -ldl -lpthread -lz -lrt -lTransform360' --enable-libvmaf --extra-cxxflags='-static -static-libstdc++ -static-libgcc' --extra-ldflags='-static -static-libstdc++ -static-libgcc' && \
        make && \
        make install

# test ffmpeg
RUN ldd $FFMPEG_PREFIX/bin/ffmpeg | grep 'not a dynamic executable'
RUN $FFMPEG_PREFIX/bin/ffmpeg -filters | grep 360
RUN $FFMPEG_PREFIX/bin/ffmpeg -h encoder=libx265 2>/dev/null | grep pixel
RUN $FFMPEG_PREFIX/bin/ffmpeg -h encoder=libx264 2>/dev/null | grep pixel
# archive
RUN cd / tar zcf ffmpeg-$FFMPEG_VER.tar.gz $FFMPEG_PREFIX
