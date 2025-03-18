FROM debian:bullseye-slim

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  apt-utils \
  bmake \
  build-essential \
  bzip2 \
  ca-certificates \
  curl \
  devscripts \
  dh-make \
  fakeroot \
  git \
  libcap-dev \
  libelf-dev \
  libseccomp-dev \
  lintian \
  lsb-release \
  m4 \
  pkg-config \
  xz-utils && \
  rm -rf /var/lib/apt/lists/*

ENV OS_ARCH="amd64"
ENV GOLANG_VERSION="1.22.5"
RUN curl https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-${OS_ARCH}.tar.gz | tar -C /usr/local -xz
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
ENV DATA_DIR=/tmp

COPY daemon.json /opt/daemon.json

RUN chmod -R 777 /opt

ENV GPG_TTY=/dev/console

CMD bash -c "cd ${DATA_DIR} && \
  git clone --depth 1 --branch v${LIBNVIDIA_VERSION} https://github.com/NVIDIA/libnvidia-container.git && \
  cd ${DATA_DIR}/libnvidia-container && \
  git checkout v${LIBNVIDIA_VERSION} && \
  sed -i '/if (syscall(SYS_pivot_root, ".", ".") < 0)/,+1 d' ${DATA_DIR}/libnvidia-container/src/nvc_ldcache.c && \
  sed -i '/if (umount2(".", MNT_DETACH) < 0)/,+1 d' ${DATA_DIR}/libnvidia-container/src/nvc_ldcache.c && \
  make GO111MODULE=auto || true; \
  mv ${DATA_DIR}/libnvidia-container/deps/src/elftoolchain-0.7.1/libelf/'name libelf.so.1' ${DATA_DIR}/libnvidia-container/deps/src/elftoolchain-0.7.1/libelf/libelf.so.1 && \
  DESTDIR=${DATA_DIR}/libnvidia-container-${LIBNVIDIA_VERSION} make LIB_VERSION=${LIBNVIDIA_VERSION} LIB_TAG=${LIBNVIDIA_VERSION} install prefix=/usr GO111MODULE=auto && \
  mkdir -p ${DATA_DIR}/libnvidia-container-${LIBNVIDIA_VERSION}/etc/docker && \
  cp /opt/daemon.json ${DATA_DIR}/libnvidia-container-${LIBNVIDIA_VERSION}/etc/docker/daemon.json && \
  cd ${DATA_DIR}/libnvidia-container-${LIBNVIDIA_VERSION} && \
  mkdir ${DATA_DIR}/v${LIBNVIDIA_VERSION} && \
  tar cfvz ${DATA_DIR}/v${LIBNVIDIA_VERSION}/libnvidia-container-v${LIBNVIDIA_VERSION}.tar.gz *"
