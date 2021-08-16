FROM ubuntu:focal-20210723 as build
ARG COCKROACH_VERSION
ENV DEBIAN_FRONTEND=noninteractive COCKROACH_VERSION=$COCKROACH_VERSION
RUN apt-get update; apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:longsleep/golang-backports
RUN apt-get -y upgrade
RUN apt-get -y install gcc golang-go cmake autoconf wget bison libncurses-dev
RUN wget -qO- https://binaries.cockroachdb.com/cockroach-v${COCKROACH_VERSION}.src.tgz | tar  xvz
WORKDIR cockroach-v${COCKROACH_VERSION}
RUN make `nproc --all` build; make `nproc --all` install

FROM ubuntu:focal-20210723
RUN apt-get update && apt-get -y upgrade && apt-get install -y libc6 ca-certificates tzdata && rm -rf /var/lib/apt/lists/*
WORKDIR /cockroach/
ENV PATH=/cockroach:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV COCKROACH_CHANNEL=kubernetes-insecure
RUN mkdir -p /cockroach/
COPY --from=build /usr/local/bin/cockroach /cockroach/cockroach
EXPOSE 26257 8080
ENTRYPOINT ["/cockroach/cockroach"]
