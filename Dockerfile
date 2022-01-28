FROM rust:bullseye as planner

ARG http_proxy
ARG https_proxy
ENV http_proxy=$http_proxy
ENV https_proxy=$https_proxy
RUN echo Acquire::http::Proxy "${http_proxy}"; > /etc/apt/apt.conf.d/70debconf

# Build electrsd
WORKDIR electrsd
# We only pay the installation cost once,
# it will be cached from the second build onwards
RUN cargo install cargo-chef 
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json

FROM rust:bullseye as cacher
WORKDIR electrsd
RUN cargo install cargo-chef
COPY --from=planner /electrsd/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM rust:bullseye as builder
WORKDIR electrsd
COPY . .
# Copy over the cached dependencies
COPY --from=cacher /electrsd/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
RUN cargo build --release


# Prepare running env required by electrsd

# Install common packages
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
       build-essential \
       ca-certificates \
       curl \
       file \
       jq \
       libsecp256k1-0 \
       libssl-dev \
       openssl \
       pkg-config git \
       syslog-ng \
       sudo \
       vim

RUN useradd -d /home/satoshi -m satoshi
ENV HOME /home/satoshi 
RUN printf "[user]\n\tname = Satoshi Nakamoto\n" > /home/satoshi/.gitconfig
#USER satoshi

