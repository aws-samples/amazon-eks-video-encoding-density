# build stage
FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy as buildstage

# set version label
ARG FFMPEG_VERSION

# common env
ENV \
  DEBIAN_FRONTEND="noninteractive" \
  MAKEFLAGS="-j4"

# versions
ENV \
  AOM=v3.7.0 \
  FDKAAC=2.0.2 \
  FFMPEG_HARD=6.1 \
  FREETYPE=2.13.2 \
  FRIBIDI=1.0.13 \
  KVAZAAR=2.2.0 \
  LAME=3.100 \
  LIBASS=0.17.1 \
  LIBDRM=2.4.116 \
  LIBVA=2.19.0 \
  LIBVDPAU=1.5 \
  LIBVIDSTAB=1.1.1 \
  NVCODEC=n12.1.14.0 \
  OGG=1.3.5 \
  OPENCOREAMR=0.1.6 \
  OPENJPEG=2.5.0 \
  OPUS=1.3.1 \
  SVTAV1=1.7.0 \
  THEORA=1.1.1 \
  VORBIS=1.3.7 \
  VPX=1.13.1 \
  WEBP=1.3.2 \
  X265=master \
  XVID=1.3.7

RUN \
  echo "**** install build packages ****" && \
  apt-get update && \
  apt-get install -y \
    autoconf \
    automake \
    bzip2 \
    cmake \
    diffutils \
    g++ \
    gcc \
    git \
    gperf \
    libexpat1-dev \
    libfontconfig1-dev \
    libgcc-10-dev \
    libgomp1 \
    libharfbuzz-dev \
    libpciaccess-dev \
    libssl-dev \
    libtool \
    libv4l-dev \
    libx11-dev \
    libxext-dev \
    libxml2-dev \
    make \
    nasm \
    perl \
    pkg-config \
    python3-venv \
    x11proto-xext-dev \
    xserver-xorg-dev \
    xxd \
    yasm \
    zlib1g-dev && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    setuptools \
    wheel && \
  pip install --no-cache-dir cmake

# compile 3rd party libs
RUN \
  echo "**** grabbing aom ****" && \
  mkdir -p /tmp/aom && \
  git clone \
    --branch ${AOM} \
    --depth 1 https://aomedia.googlesource.com/aom \
    /tmp/aom
RUN \
  echo "**** compiling aom ****" && \
  cd /tmp/aom && \
  rm -rf \
    CMakeCache.txt \
    CMakeFiles && \
  mkdir -p \
    aom_build && \
  cd aom_build && \
  cmake \
    -DBUILD_STATIC_LIBS=0 .. && \
  make && \
  make install
RUN \
  echo "**** grabbing fdk-aac ****" && \
  mkdir -p /tmp/fdk-aac && \
  curl -Lf \
    https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/fdk-aac
RUN \
  echo "**** compiling fdk-aac ****" && \
  cd /tmp/fdk-aac && \
  autoreconf -fiv && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing freetype ****" && \
  mkdir -p /tmp/freetype && \
  curl -Lf \
    https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE}/freetype-${FREETYPE}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/freetype
RUN \
  echo "**** compiling freetype ****" && \
  cd /tmp/freetype && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing fribidi ****" && \
  mkdir -p /tmp/fribidi && \
  curl -Lf \
    https://github.com/fribidi/fribidi/archive/v${FRIBIDI}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/fribidi
RUN \
  echo "**** compiling fribidi ****" && \
  cd /tmp/fribidi && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make -j 1 && \
  make install
RUN \
  echo "**** grabbing kvazaar ****" && \
  mkdir -p /tmp/kvazaar && \
  curl -Lf \
    https://github.com/ultravideo/kvazaar/archive/v${KVAZAAR}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/kvazaar
RUN \
  echo "**** compiling kvazaar ****" && \
  cd /tmp/kvazaar && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing lame ****" && \
  mkdir -p /tmp/lame && \
  curl -Lf \
    http://downloads.sourceforge.net/project/lame/lame/${LAME}/lame-${LAME}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/lame
RUN \
  echo "**** compiling lame ****" && \
  cd /tmp/lame && \
  cp \
    /usr/share/automake-1.16/config.guess \
    config.guess && \
  cp \
    /usr/share/automake-1.16/config.sub \
    config.sub && \
  ./configure \
    --disable-frontend \
    --disable-static \
    --enable-nasm \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing libass ****" && \
  mkdir -p /tmp/libass && \
  curl -Lf \
    https://github.com/libass/libass/archive/${LIBASS}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/libass
RUN \
  echo "**** compiling libass ****" && \
  cd /tmp/libass && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing ogg ****" && \
  mkdir -p /tmp/ogg && \
  curl -Lf \
    http://downloads.xiph.org/releases/ogg/libogg-${OGG}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/ogg
RUN \
  echo "**** compiling ogg ****" && \
  cd /tmp/ogg && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing opencore-amr ****" && \
  mkdir -p /tmp/opencore-amr && \
  curl -Lf \
    http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/opencore-amr
RUN \
  echo "**** compiling opencore-amr ****" && \
  cd /tmp/opencore-amr && \
  ./configure \
    --disable-static \
    --enable-shared  && \
  make && \
  make install
RUN \
  echo "**** grabbing openjpeg ****" && \
  mkdir -p /tmp/openjpeg && \
  curl -Lf \
    https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/openjpeg
RUN \
  echo "**** compiling openjpeg ****" && \
  cd /tmp/openjpeg && \
  rm -Rf \
    thirdparty/libpng/* && \
  curl -Lf \
    https://download.sourceforge.net/libpng/libpng-1.6.37.tar.gz | \
    tar -zx --strip-components=1 -C thirdparty/libpng/ && \
  cmake \
    -DBUILD_STATIC_LIBS=0 \
    -DBUILD_THIRDPARTY:BOOL=ON . && \
  make && \
  make install
RUN \
  echo "**** grabbing opus ****" && \
  mkdir -p /tmp/opus && \
  curl -Lf \
    https://archive.mozilla.org/pub/opus/opus-${OPUS}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/opus
RUN \
  echo "**** compiling opus ****" && \
  cd /tmp/opus && \
  autoreconf -fiv && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing SVT-AV1 ****" && \
  mkdir -p /tmp/svt-av1 && \
  curl -Lf \
    https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v${SVTAV1}/SVT-AV1-v${SVTAV1}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/svt-av1
RUN \
  echo "**** compiling SVT-AV1 ****" && \
  cd /tmp/svt-av1/Build && \
  cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
  make && \
  make install
RUN \
  echo "**** grabbing theora ****" && \
  mkdir -p /tmp/theora && \
  curl -Lf \
    http://downloads.xiph.org/releases/theora/libtheora-${THEORA}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/theora
RUN \
  echo "**** compiling theora ****" && \
  cd /tmp/theora && \
  cp \
    /usr/share/automake-1.16/config.guess \
    config.guess && \
  cp \
    /usr/share/automake-1.16/config.sub \
    config.sub && \
  curl -fL \
    'https://gitlab.xiph.org/xiph/theora/-/commit/7288b539c52e99168488dc3a343845c9365617c8.diff' \
    > png.patch && \
  patch ./examples/png2theora.c < png.patch && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing vid.stab ****" && \
  mkdir -p /tmp/vid.stab && \
  curl -Lf \
    https://github.com/georgmartius/vid.stab/archive/v${LIBVIDSTAB}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/vid.stab
RUN \
  echo "**** compiling vid.stab ****" && \
  cd /tmp/vid.stab && \
  echo "" > \
    CMakeModules/FindSSE.cmake && \
  cmake . && \
  make && \
  make install
RUN \
  echo "**** grabbing vorbis ****" && \
  mkdir -p /tmp/vorbis && \
  curl -Lf \
    http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/vorbis
RUN \
  echo "**** compiling vorbis ****" && \
  cd /tmp/vorbis && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing vpx ****" && \
  mkdir -p /tmp/vpx && \
  curl -Lf \
    https://github.com/webmproject/libvpx/archive/v${VPX}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/vpx
RUN \
  echo "**** compiling vpx ****" && \
  cd /tmp/vpx && \
  ./configure \
    --disable-debug \
    --disable-docs \
    --disable-examples \
    --disable-install-bins \
    --disable-static \
    --disable-unit-tests \
    --enable-pic \
    --enable-shared \
    --enable-vp8 \
    --enable-vp9 \
    --enable-vp9-highbitdepth && \
  make && \
  make install
RUN \
  echo "**** grabbing webp ****" && \
  mkdir -p /tmp/webp && \
  curl -Lf \
    https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/webp
RUN \
  echo "**** compiling webp ****" && \
  cd /tmp/webp && \
  ./configure && \
  make && \
  make install
RUN \
  echo "**** grabbing x264 ****" && \
  mkdir -p /tmp/x264 && \
  curl -Lf \
    https://code.videolan.org/videolan/x264/-/archive/master/x264-stable.tar.bz2 | \
    tar -jx --strip-components=1 -C /tmp/x264
RUN \
  echo "**** compiling x264 ****" && \
  cd /tmp/x264 && \
  ./configure \
    --disable-cli \
    --disable-static \
    --enable-pic \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing x265 ****" && \
  mkdir -p /tmp/x265 && \
  git clone \
    --branch ${X265} \
    https://bitbucket.org/multicoreware/x265_git.git \
    /tmp/x265
RUN \
  echo "**** compiling x265 ****" && \
  cd /tmp/x265/build/linux && \
  export CXXFLAGS="-fPIC" && \
  ./multilib.sh && \
  make -C 8bit install
RUN \
  echo "**** grabbing xvid ****" && \
  mkdir -p /tmp/xvid && \
  curl -Lf \
    https://downloads.xvid.com/downloads/xvidcore-${XVID}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/xvid
RUN \
  echo "**** compiling xvid ****" && \
  cd /tmp/xvid/build/generic && \
  ./configure && \
  make && \
  make install


RUN \
  echo "**** grabbing ffnvcodec ****" && \
  mkdir -p /tmp/ffnvcodec && \
  git clone \
    --branch ${NVCODEC} \
    --depth 1 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
    /tmp/ffnvcodec
RUN \
  echo "**** compiling ffnvcodec ****" && \
  cd /tmp/ffnvcodec && \
  make install

# main ffmpeg build
RUN \
  echo "**** Versioning ****" && \
  if [ -z ${FFMPEG_VERSION+x} ]; then \
    FFMPEG=${FFMPEG_HARD}; \
  else \
    FFMPEG=${FFMPEG_VERSION%-cli}; \
  fi && \
  echo "**** grabbing ffmpeg ****" && \
  mkdir -p /tmp/ffmpeg && \
  echo "https://ffmpeg.org/releases/ffmpeg-${FFMPEG}.tar.bz2" && \
  curl -Lf \
    https://ffmpeg.org/releases/ffmpeg-${FFMPEG}.tar.bz2 | \
    tar -jx --strip-components=1 -C /tmp/ffmpeg
RUN \
  echo "**** compiling ffmpeg ****" && \
  cd /tmp/ffmpeg && \
  ./configure \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --enable-ffprobe \
    --enable-gpl \
    --enable-cuvid \
    --enable-libaom \
    --enable-libass \
    --enable-libfdk_aac \
    --enable-libfreetype \
    --enable-libkvazaar \
    --enable-libmp3lame \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopenjpeg \
    --enable-libopus \
    --enable-libsvtav1 \
    --enable-libtheora \
    --enable-libv4l2 \
    --enable-libvidstab \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libxml2 \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxvid \
    --enable-libwebp \
    --enable-nonfree \
    --enable-nvdec \
    --enable-nvenc \
    --enable-openssl \
    --enable-stripping \
    --enable-version3 && \
  make

RUN \
  echo "**** arrange files ****" && \
  ldconfig && \
  mkdir -p \
    /buildout/usr/local/bin \
    /buildout/usr/local/lib && \
  cp \
    /tmp/ffmpeg/ffmpeg \
    /buildout/usr/local/bin && \
  cp \
    /tmp/ffmpeg/ffprobe \
    /buildout/usr/local/bin && \
  cp -a \
    /usr/local/lib/lib*so* \
    /buildout/usr/local/lib/

# runtime stage
FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# Add files from binstage
COPY --from=buildstage /buildout/ /

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

ARG DEBIAN_FRONTEND="noninteractive"

ENV \
  LD_LIBRARY_PATH="/usr/local/lib" \
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all"

RUN \
  echo "**** install runtime ****" && \
  apt-get update && \
  apt-get install -y \
    libexpat1 \
    libfontconfig1 \
    libglib2.0-0 \
    libgomp1 \
    libharfbuzz0b \
    libv4l-0 \
    libx11-6 \
    libxcb1 \
    libxext6 \
    libxml2 && \
  echo "**** clean up ****" && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*

COPY ./ffmpegwrapper.sh /
#Uncomment the below or add your own video file to test:
#COPY ./bbb_sunflower_1080p_30fps_normal.mp4 ./bbb_sunflower_1080p_30fps_normal.mp4
#COPY ./bbb_sunflower_1080p_25fps_normal.ts ./bbb_sunflower_1080p_25fps_normal.ts

ENTRYPOINT ["/ffmpegwrapper.sh"]