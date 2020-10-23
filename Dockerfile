######## Start builder #######
FROM ubuntu:20.04

USER root

# Required so that pipes work properly in the Dockerfile
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

# Package installations
RUN apt-get update && \
    apt-get install -y \
    ack-grep \
    build-essential \
    git \
    curl \
    docker.io \
    libssl-dev \
    vim

# Pegasus release file and key paths
ENV PEGASUS_GIT_REPOSITORY=git@github.com:KSchopmeyer/OpenPegasus.git
ENV PEGASUS_SMI_ROOT=/root/smi
ENV PEGASUS_HOME=${PEGASUS_SMI_ROOT}/home
ENV PEGASUS_ROOT=${PEGASUS_SMI_ROOT}/OpenPegasus/pegasus

# Create directory structure
RUN mkdir -p ${PEGASUS_HOME} && \
    mkdir -p /root/.ssh

# Build settings (Debug is currently required for successful building)
# Settings below that are flags, with values set to true, enable the action
# simply through the existance of the variable.  The variables value has no
# effect.
ENV PEGASUS_PLATFORM=LINUX_X86_64_GNU
ENV PEGASUS_DEBUG=true
ENV PATH=${PEGASUS_HOME}/bin:$PATH
ENV PEGASUS_USE_DEFAULT_MESSAGES=true
#ENV PEGASUS_HAS_SSL=true
ENV PEGASUS_CLIENT_TRACE_ENABLE=true
ENV PEGASUS_ENABLE_EXECQUERY=true
ENV OPENSSL=/usr

# Add files for building the server image
COPY ./makefile ${PEGASUS_SMI_ROOT}
COPY ./Dockerfile_smi-server ${PEGASUS_SMI_ROOT}/Dockerfile

# Build folder
WORKDIR ${PEGASUS_SMI_ROOT}

# Build the binaries and run the cimserver
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["make build"]