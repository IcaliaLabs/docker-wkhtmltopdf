# Stage I: Runtime Dependencies ================================================
#
# This stage will be the base image for the rest of the stages, and will include
# the required packages for the final wkhtmltopdf executable to work properly:
FROM buildpack-deps:stretch-curl AS runtime-deps

# 1: Set the wkhtmltopdf version into an environment variable:
ENV WKHTMLTOX_VERSION=0.12.5

# 2: Install the runtime dependency packages using apt-get:
RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  fontconfig \
  fontconfig-config \
  fonts-dejavu-core \
  libbsd0 \
  libexpat1 \
  libfontconfig1 \
  libfontenc1 \
  libfreetype6 \
  libjpeg62-turbo \
  libpng16-16 \
  libssl1.1 \
  libx11-6 \
  libx11-data \
  libxau6 \
  libxcb1 \
  libxdmcp6 \
  libxext6 \
  libxfont1 \
  libxrender1 \
  ucf \
  x11-common \
  xfonts-75dpi \
  xfonts-base \
  xfonts-encodings \
  xfonts-utils \
 && rm -rf /var/lib/apt/lists/*

# Stage 2: Builder =============================================================
#
# In this stage will fetch the wkhtmltopdf .deb file from wkhtmltopdf.org, and
# install it using apt (which in turn runs dpkg):
FROM runtime-deps AS builder

# 1: Set the .deb SHA256 checksum into an environment variable:
ENV WKHTMLTOX_VERSION_SHA_256=1140b0ab02aa6e17346af2f14ed0de807376de475ba90e1db3975f112fbd20bb

# 2: Fetch the .deb file & install:
RUN curl -L -o /wkhtmltox.deb https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
 && echo "$WKHTMLTOX_VERSION_SHA_256 *wkhtmltox.deb" | sha256sum -c - \
 && dpkg -i /wkhtmltox.deb

# Stage III: Distributable image: ==============================================
#
# Once wkhtmltopdf has been built, we'll start off again from the runtime-deps
# stage, so we can have a 'clean slate', and a smaller docker image:
FROM runtime-deps AS distributable

# 1: Copy the wkhtmltopdf executable:
COPY --from=builder /usr/local/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf

# 2: Set wkhtmltopdf as the entrypoint for the containers:
ENTRYPOINT ["/usr/local/bin/wkhtmltopdf"]
