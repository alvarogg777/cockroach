FROM --platform=$BUILDPLATFORM ubuntu:focal-20220531 as build
ARG COCKROACH_VERSION
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ENV DEBIAN_FRONTEND=noninteractive COCKROACH_VERSION=$COCKROACH_VERSION TARGETPLATFORM=$TARGETPLATFORM
RUN apt-get update; apt-get install -qqy software-properties-common
RUN add-apt-repository -y ppa:longsleep/golang-backports;
RUN apt-get -qqy upgrade
RUN apt-get -qqy install gcc golang-go cmake autoconf wget bison libncurses-dev git ccache tzdata libc6 ca-certificates
RUN export arch=`uname -m`; if [ $arch = "aarch64" ]; then arch="arm64"; else arch=$arch; fi; wget https://github.com/bazelbuild/bazel/releases/download/4.2.1/bazel-4.2.1-linux-$arch -O /usr/bin/bazel ; chmod +x /usr/bin/bazel
RUN wget -qO- https://binaries.cockroachdb.com/cockroach-v${COCKROACH_VERSION}.src.tgz | tar  xz
WORKDIR cockroach-v${COCKROACH_VERSION}
RUN make -j `nproc --all` build; make -j `nproc --all` install

FROM ubuntu:focal-20220531
RUN apt-get update && apt-get -qqy upgrade && apt-get install -qqy libc6 ca-certificates tzdata && rm -rf /var/lib/apt/lists/*
WORKDIR /cockroach/
ENV PATH=/cockroach:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV COCKROACH_CHANNEL=kubernetes-insecure
RUN mkdir -p /cockroach/
COPY --from=build /usr/local/bin/cockroach /cockroach/cockroach
COPY ./cockroach.sh /cockroach/cockroach.sh
EXPOSE 26257 8080
ENTRYPOINT ["/cockroach/cockroach.sh"]
