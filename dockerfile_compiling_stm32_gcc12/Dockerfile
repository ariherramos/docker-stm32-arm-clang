FROM ubuntu:22.04

LABEL version="0.1"
LABEL description="Imagem Docker para compilacao STM32 com toolchain GNU Arm e CMake oficial"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Brasilia

ARG CMAKE_VERSION=3.24.1
ARG ARM_GNU_TOOLCHAIN_VERSION=12.3.rel1
ARG NRF_TOOLS_VERSION=10.24.2

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential git wget curl ca-certificates unzip python3 python3-pip \
        udev libusb-1.0-0-dev libncurses5 libncurses5-dev libpython2.7 libpython2.7-minimal \
        ninja-build expect libftdi1-2 libusb-0.1-4 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" -O /tmp/cmake-install.sh \
    && chmod +x /tmp/cmake-install.sh \
    && mkdir -p /opt/cmake-${CMAKE_VERSION} \
    && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-${CMAKE_VERSION} \
    && rm -f /tmp/cmake-install.sh \
    && ln -sf /opt/cmake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/cmake \
    && ln -sf /opt/cmake-${CMAKE_VERSION}/bin/ctest /usr/local/bin/ctest \
    && ln -sf /opt/cmake-${CMAKE_VERSION}/bin/cpack /usr/local/bin/cpack

RUN wget -q "https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_GNU_TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${ARM_GNU_TOOLCHAIN_VERSION}-x86_64-arm-none-eabi.tar.xz" -O /tmp/arm-gnu-toolchain.tar.xz \
    && mkdir -p /opt/gcc-arm-none-eabi \
    && tar -xf /tmp/arm-gnu-toolchain.tar.xz -C /opt/gcc-arm-none-eabi --strip-components=1 \
    && rm -f /tmp/arm-gnu-toolchain.tar.xz \
    && ln -sf /opt/gcc-arm-none-eabi/bin/arm-none-eabi-gcc /usr/local/bin/arm-none-eabi-gcc \
    && ln -sf /opt/gcc-arm-none-eabi/bin/arm-none-eabi-g++ /usr/local/bin/arm-none-eabi-g++ \
    && ln -sf /opt/gcc-arm-none-eabi/bin/arm-none-eabi-ar /usr/local/bin/arm-none-eabi-ar \
    && ln -sf /opt/gcc-arm-none-eabi/bin/arm-none-eabi-objcopy /usr/local/bin/arm-none-eabi-objcopy \
    && ln -sf /opt/gcc-arm-none-eabi/bin/arm-none-eabi-objdump /usr/local/bin/arm-none-eabi-objdump \
    && ln -sf /opt/gcc-arm-none-eabi/bin/arm-none-eabi-size /usr/local/bin/arm-none-eabi-size \
    && ln -sf /opt/gcc-arm-none-eabi/bin/arm-none-eabi-ld /usr/local/bin/arm-none-eabi-ld

ENV PATH="/opt/gcc-arm-none-eabi/bin:/usr/local/bin:${PATH}"

RUN set -eux; \
    NRF_URL="https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/${NRF_TOOLS_VERSION}/nrf-command-line-tools_${NRF_TOOLS_VERSION}_amd64.deb"; \
    if wget -q --spider "$NRF_URL"; then \
        wget -q -O /tmp/nrf-command-line-tools.deb "$NRF_URL"; \
        dpkg -i /tmp/nrf-command-line-tools.deb || true; \
        apt-get -f install -y || true; \
    else \
        echo "nRF Command Line Tools indisponivel no momento; pulando instalacao"; \
    fi; \
    rm -f /tmp/nrf-command-line-tools.deb; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN cmake --version && arm-none-eabi-gcc --version | head -n 1

