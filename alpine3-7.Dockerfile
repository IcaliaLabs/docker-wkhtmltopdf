# Stage I: Runtime Dependencies ================================================
#
# This stage will be the base image for the rest of the stages, and will include
# the required packages for the final wkhtmltopdf executable to work properly:
FROM alpine:3.7 AS runtime-deps

# 1: Set the wkhtmltopdf version into an environment variable:
ENV WKHTMLTOX_VERSION=0.12.5

# 2: Install the runtime dependency packages using apk:
RUN apk add --no-cache \
 libstdc++ \
 libx11 \
 libxrender \
 libxext \
 libssl1.0 \
 ca-certificates \
 fontconfig \
 freetype \
 ttf-dejavu \
 ttf-droid \
 ttf-freefont \
 ttf-liberation \
 ttf-ubuntu-font-family

# Stage 2: Builder =============================================================
#
# In this stage will build qt and wkthml. For this, we'll need to download the
# build dependencies, fetch the wkhtmltopdf code - which includes the qt code -,
# patch qt, build qt and finally build wkhtmltopdf:
FROM runtime-deps AS builder

# 1: Install development & compiler packages using the alpine package manager:
RUN apk add --no-cache \
 g++ \
 git \
 gtk+ \
 gtk+-dev \
 make \
 mesa-dev \
 openssl-dev \
 patch \
 fontconfig-dev \
 freetype-dev

# 2: Copy the patches:
COPY conf/* /tmp/patches/

# 3: Fetch the wkhtmltopdf code, including the qt submodule; checkout the
# required wkhtmltopdf version tag, and apply the patches & edits:
RUN git clone --recursive https://github.com/wkhtmltopdf/wkhtmltopdf.git /tmp/wkhtmltopdf \
 && cd /tmp/wkhtmltopdf \
 && git checkout $WKHTMLTOX_VERSION \
 && cd qt \
 # Apply the patches:
 && patch -p1 -i /tmp/patches/qt-musl.patch \
 && patch -p1 -i /tmp/patches/qt-musl-iconv-no-bom.patch \
 && patch -p1 -i /tmp/patches/qt-recursive-global-mutex.patch \
 && patch -p1 -i /tmp/patches/qt-gcc6.patch \
 # Modify qmake config:
 && sed -i "s|-O2|$CXXFLAGS|" mkspecs/common/g++.conf \
 && sed -i "/^QMAKE_RPATH/s| -Wl,-rpath,||g" mkspecs/common/g++.conf \
 && sed -i "/^QMAKE_LFLAGS\s/s|+=|+= $LDFLAGS|g" mkspecs/common/g++.conf

# 4: Build & Install qt:
RUN cd /tmp/wkhtmltopdf/qt \
 && export NB_CORES=$(grep -c '^processor' /proc/cpuinfo) \
 && ./configure -confirm-license -opensource \
  -prefix /usr \
  -datadir /usr/share/qt \
  -sysconfdir /etc \
  -plugindir /usr/lib/qt/plugins \
  -importdir /usr/lib/qt/imports \
  -silent \
  -release \
  -static \
  -webkit \
  -script \
  -svg \
  -exceptions \
  -xmlpatterns \
  -openssl-linked \
  -no-fast \
  -no-largefile \
  -no-accessibility \
  -no-stl \
  -no-sql-ibase \
  -no-sql-mysql \
  -no-sql-odbc \
  -no-sql-psql \
  -no-sql-sqlite \
  -no-sql-sqlite2 \
  -no-qt3support \
  -no-opengl \
  -no-openvg \
  -no-system-proxies \
  -no-multimedia \
  -no-audio-backend \
  -no-phonon \
  -no-phonon-backend \
  -no-javascript-jit \
  -no-scripttools \
  -no-declarative \
  -no-declarative-debug \
  -no-mmx \
  -no-3dnow \
  -no-sse \
  -no-sse2 \
  -no-sse3 \
  -no-ssse3 \
  -no-sse4.1 \
  -no-sse4.2 \
  -no-avx \
  -no-neon \
  -no-rpath \
  -no-nis \
  -no-cups \
  -no-pch \
  -no-dbus \
  -no-separate-debug-info \
  -no-gtkstyle \
  -no-nas-sound \
  -no-opengl \
  -no-openvg \
  -no-sm \
  -no-xshape \
  -no-xvideo \
  -no-xsync \
  -no-xinerama \
  -no-xcursor \
  -no-xfixes \
  -no-xrandr \
  -no-mitshm \
  -no-xinput \
  -no-xkb \
  -no-glib \
  -no-icu \
  -nomake demos \
  -nomake docs \
  -nomake examples \
  -nomake tools \
  -nomake tests \
  -nomake translations \
  -graphicssystem raster \
  -qt-zlib \
  -qt-libpng \
  -qt-libmng \
  -qt-libtiff \
  -qt-libjpeg \
  -optimized-qmake \
  -iconv \
  -xrender \
  -fontconfig \
  -D ENABLE_VIDEO=0 \
 && make --jobs $(($NB_CORES*2)) --silent \
 && make install

# 5: Build and install wkhtmltopdf
RUN cd /tmp/wkhtmltopdf \
 && export NB_CORES=$(grep -c '^processor' /proc/cpuinfo) \
 && qmake \
 && make --jobs $(($NB_CORES*2)) --silent \
 && make install \
 && make clean \
 && make distclean

# Stage III: Distributable image: ==============================================
#
# Once wkhtmltopdf has been built, we'll start off again from the runtime-deps
# stage, so we can have a 'clean slate', and a smaller docker image:
FROM runtime-deps AS distributable

# 1: Copy the wkhtmltopdf executable:
COPY --from=builder /bin/wkhtmltopdf /bin/wkhtmltopdf

# 2: Copy the entrypoint script:
COPY ./alpine-entrypoint.sh /bin/entrypoint.sh

# 2: Set wkhtmltopdf as the entrypoint:
ENTRYPOINT ["/bin/entrypoint.sh"]
