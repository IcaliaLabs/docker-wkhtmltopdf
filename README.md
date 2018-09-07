# wkhtmltopdf

Dockerized wkhtmltopdf

## Supported tags and respective Dockerfile links
- 0.12.5-alpine3.7, 0.12-alpine3.7, 0.12-alpine, 0.12, latest ([https://github.com/IcaliaLabs/docker-wkhtmltopdf/master/blob](2.6-rc/stretch/Dockerfile))

## Standalone usage

```
# The example found at https://wkhtmltopdf.org:
docker run --rm -v $(pwd):/root icalialabs/wkhtmltopdf http://google.com google.pdf
```

## Including the compiled binary into your Dockerfiles

Instead of directly basing your Dockerfile from this image, try copying instead
the executable from this image. You'll need to install the dependency packages
for wkhtmltopdf to work:

```
# 1: Start from whatever image you are using - this is a ruby app example:
FROM ruby:alpine

# 2: Install the packages required for wkhtmltopdf to work:
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

# 3: Copy the wkhtmltopdf executable binary directly from our image:
COPY --from icalialabs/wkhtmltopdf:alpine /bin/wkhtmltopdf /bin/wkhtmltopdf

# 4: Continue with the rest of your Dockerfile:
COPY Gemfile* /usr/src/
```

## References

### Similar projects:
- https://github.com/Surnet/docker-wkhtmltopdf
- https://github.com/aantonw/docker-alpine-wkhtmltopdf-patched-qt
- https://github.com/alloylab/Docker-Alpine-wkhtmltopdf
