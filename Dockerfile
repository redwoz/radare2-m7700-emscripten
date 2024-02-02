# docker build -t r2docker:latest .

# docker run -t r2docker:latest sh -c "rasm2 -L"
# =>
#  Disassembly plugin for Mitsubishi M7700 Arch

# docker run -t r2docker:latest sh -c "rasm2 -a m7700 -b 32 -d 'D8AD94404AC900019003'"
# =>
#  CLM
#  LDA 0x4094 --  m:0 x:0
#  LSR ax --  m:0 x:0
#  CMP ax #0x0100 --  m:0 x:0
#  BCC 0x0d --  m:0 x:0

##

# Using debian 10 as base image.
# FROM debian:10
FROM ubuntu:22.04

# Label base
LABEL r2docker latest

# Radare version
ARG R2_VERSION=5.7.8
# Capstone version
ARG CAPSTONE_VERSION=4.0.2
# R2pipe python version
ARG R2_PIPE_PY_VERSION=1.6.5

# ARG with_arm32_as
# ARG with_arm64_as
ARG with_ppc_as

ENV R2_VERSION ${R2_VERSION}
ENV R2_PIPE_PY_VERSION ${R2_PIPE_PY_VERSION}

RUN echo -e "Building versions:\n\
  R2_VERSION=$R2_VERSION\n\
  R2_PIPE_PY_VERSION=${R2_PIPE_PY_VERSION}"

# Build radare2 in a volume to minimize space used by build
VOLUME ["/mnt"]

# Install all build dependencies
# Install bindings
# Build and install radare2 on master branch
# Remove all build dependencies
# Cleanup
RUN DEBIAN_FRONTEND=noninteractive dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install -y \
  curl \
  wget \
  gcc \
  git \
  bison \
  pkg-config \
  make \
  glib-2.0 \
  libc6:i386 \
  libncurses5:i386 \
  libstdc++6:i386 \
  gnupg2 \
  python3-pip \
  zip
  #  \
  # # ${with_arm64_as:+binutils-aarch64-linux-gnu} \
  # # ${with_arm32_as:+binutils-arm-linux-gnueabi} \
  # ${with_ppc_as:+binutils-powerpc64le-linux-gnu}
  
RUN pip install r2pipe=="$R2_PIPE_PY_VERSION"

# install capstone v4; just this being installed overcomes issues with radare2 build...
RUN cd /mnt && \
  git clone -b "$CAPSTONE_VERSION" -q --depth 1 https://github.com/capstone-engine/capstone.git && \
  cd capstone && \
  ./make.sh && \
  ./make.sh install

# # doesnt work...: zip error: Nothing to do! (r2js.zip)
# RUN cd /mnt && \
#   cd radare2 && \
#   source /mnt/emsdk/emsdk_env.sh && \
#   sys/emscripten.sh

RUN cd /mnt && \
  git clone -b "$R2_VERSION" -q --depth 1 https://github.com/radareorg/radare2.git && \
  cd radare2 && \
  sys/install.sh --with-syscapstone

SHELL ["/bin/bash", "-c"]

RUN cd /mnt && \
  git clone -q --depth 1 https://github.com/emscripten-core/emsdk.git && \
  cd emsdk && \
  ./emsdk install latest && \
  ./emsdk activate latest && \
  chmod +x ./emsdk_env.sh && \
  ./emsdk_env.sh

# # doesnt work...:
# #   1.502 wasm-ld: error: unknown file type: asm_m7700.o
# #   1.502 emcc: error: '/mnt/emsdk/upstream/bin/wasm-ld -o asm_m7700.so asm_m7700.o -L/mnt/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten --relocatable -mllvm -combiner-global-alias-analysis=false -mllvm -enable-emscripten-sjlj -mllvm -disable-lsr' failed (returned 1)
# RUN cd /mnt && \
#   git clone -q --depth 1 https://github.com/redwoz/r2-m7700.git && \
#   cd r2-m7700 && \
#   mkdir -p ./r2_bin/include/libr/ && \
#   cp -r /mnt/radare2/libr/include/* ./r2_bin/include/libr/ && \
#   source /mnt/emsdk/emsdk_env.sh && \
#   emmake make && \
#   emmake make install

RUN cd /mnt && \
  git clone -q --depth 1 https://github.com/redwoz/r2-m7700.git && \
  cd r2-m7700 && \
  mkdir -p ./r2_bin/include/libr/ && \
  cp -r /mnt/radare2/libr/include/* ./r2_bin/include/libr/ && \
  make && \
  make install


# Base command for container
CMD ["/bin/bash"]

####################
