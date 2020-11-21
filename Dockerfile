######## Start builder #######
FROM ubuntu:20.04

# Ignore DL3002: Last user should not be root.
# hadolint ignore=DL3002
USER root

# Required so that pipes work properly in the Dockerfile
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

# Package installations
# Includes packages for docker, OpenPegasus support packages, and
# packages to support the development environment
# Ignore DL3008: Pin versions in apt-get install.
# hadolint ignore=DL3008
# NOTE: The upgrade is absolutely required for ubuntu 20.04 becase the
# pam dev lib was left out of the original release.
# The libpam0g-dev may have different names under other linux distributions.
# the --no-install-recommends significantly reduces docker image size

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    openssl \
    docker.io \
    build-essential \
    libssl-dev \
    libpam0g-dev \
    ack-grep \
    git \
    curl \
    openssh-client \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Pegasus file paths
ENV PEGASUS_SMI_ROOT=/root/smi
ENV PEGASUS_HOME=${PEGASUS_SMI_ROOT}/home
ENV PEGASUS_ROOT=${PEGASUS_SMI_ROOT}/OpenPegasus/pegasus

# Create directory structure
RUN mkdir -p ${PEGASUS_HOME} && \
    mkdir -p /root/.ssh

# Build settings (Debug is currently required for build success)
# Settings below that are flags, with values set to true, enable the action
# simply through the existance of the variable.  The variables value has no
# effect.
ENV PEGASUS_PLATFORM=LINUX_X86_64_GNU
ENV PEGASUS_DEBUG=true
ENV PATH=${PEGASUS_HOME}/bin:$PATH
ENV PEGASUS_USE_DEFAULT_MESSAGES=true
ENV PEGASUS_HAS_SSL=true
ENV PEGASUS_PAM_AUTHENTICATION=true
ENV PEGASUS_CLIENT_TRACE_ENABLE=true
ENV PEGASUS_ENABLE_EXECQUERY=true
ENV OPENSSL=/usr

# Add files for building the server image
COPY ./makefile_smi-build ${PEGASUS_SMI_ROOT}/makefile
COPY ./Dockerfile_smi-server ${PEGASUS_SMI_ROOT}/Dockerfile

# Build folder
WORKDIR ${PEGASUS_SMI_ROOT}

# Build the binaries and run the cimserver
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["make build"]
