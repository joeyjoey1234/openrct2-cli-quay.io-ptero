# Build OpenRCT2
FROM quay.io/catthehacker/ubuntu:act-20.04 AS build-env
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y git cmake pkg-config ninja-build clang-10 duktape-dev libsdl2-dev libspeexdsp-dev nlohmann-json3-dev libcurl4-openssl-dev libcrypto++-dev libfontconfig1-dev libfreetype6-dev libpng-dev libzip-dev libssl-dev libicu-dev \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/bin/clang-10 /usr/bin/clang \
 && ln -s /usr/bin/clang++-10 /usr/bin/clang++

ENV OPENRCT2_REF v0.3.4
WORKDIR /container
RUN git -c http.sslVerify=false clone --depth 1 -b $OPENRCT2_REF https://github.com/OpenRCT2/OpenRCT2 . \
 && mkdir build \
 && cd build \
 && cmake .. -G Ninja -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=/openrct2-install/usr \
 && ninja -k0 install \
 && rm /openrct2-install/usr/lib/libopenrct2.a

# Build runtime image
FROM quay.io/catthehacker/ubuntu:act-20.04
# Install OpenRCT2
COPY --from=build-env /openrct2-install /openrct2-install
RUN apt-get update \
 && apt-get install -y rsync ca-certificates libduktape205 libpng16-16 libzip5 libcurl4 libfreetype6 libfontconfig1 libicu66  libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 libsdl2-2.0-0 libspeex-dev cmake pkg-config ninja-build duktape-dev libsdl2-dev libspeexdsp-dev nlohmann-json3-dev libcurl4-openssl-dev libcrypto++-dev libfontconfig1-dev libfreetype6-dev libpng-dev libzip-dev libssl-dev libicu-dev \
 && rm -rf /var/lib/apt/lists/* \
 && rsync -a /openrct2-install/* / \
 && rm -rf /openrct2-install \
 && openrct2-cli --version \
 && sysctl -w net.ipv6.conf.all.disable_ipv6=1 \
 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 \
 && sysctl -w net.ipv6.conf.lo.disable_ipv6=1 

# Set up ordinary user
USER root
WORKDIR /home/container


# Test run and scan
RUN openrct2-cli --version \
 && openrct2-cli scan-objects

# Done
COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]
