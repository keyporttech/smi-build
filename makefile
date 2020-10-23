# Copyright 2020 Keyport Techonologies, Inc.  All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Usage:
#
# make        	Same as "make all".
# make all    	Build and publish a server image.
# make build  	Build the server image.
# make test   	Run tests against the built server.
# make publish  Build the server, a server image and push the image to an image registry.
# make clean	Remove build output, build image and server images.
#
# Notes:
#
# 1. Build only runs the build and tests the server.  The folder home will
#    contain the built server.
# 2. Publish will build, test, create the server image and push it to an image
#    registry.
# 3. The ~/.ssh folder and the Docker-in-Docker folder need to be mapped
#    volumes when running a make command.
#
#    sudo docker run -it --rm \
#                    -v /home/<username>/.ssh:/root/.ssh \
#                    -v /var/run/docker.sock:/var/run/docker.sock \
#	                 smi-build:tag \
#					 "make build"

DOCKER_REGISTRY=registry.keyporttech.com

BUILD_IMAGE=smi-build
BUILD_IMAGE_VERSION=0.1.0

SERVER_IMAGE=smi-server
SERVER_IMAGE_VERSION=0.1.2


SHELL=/bin/bash

.ONESHELL:
.PHONY: all build test publish clean


# Top-level build targets
all: build \
	 publish

build: clone-repository \
	   build-server \
	   test-server

publish: build \
		 docker-build-server-image \
		 docker-push-server-image

test: test-server

clean: clean-build \ 
	   docker-clean-images

# Subtargets for build
clone-repository:
	@echo "Cloning OpenPegasus GitHub respository using build container..."

	@echo "Listing the current environment path..."
	@echo ${PATH}

	@echo "Changing to SMI root directory..."
	cd ${PEGASUS_SMI_ROOT}
		
	@echo "Cloning OpenPegasus under the SMI root directory..."
	git clone ${PEGASUS_GIT_REPOSITORY}	
	
build-server:
	@echo "Building the server using the build container..."

	@echo "Changing to pegasus root directory..."
	cd ${PEGASUS_ROOT}

	@echo "Building the server using the pegasus source..."
	make build

test-server:
	@echo "Testing the server using the build container..."

	@echo "Changing to pegasus root directory..."
	cd ${PEGASUS_ROOT}

	@echo "Testing the server build..."
	make tests

# Subtargets for publish
docker-build-server-image:
	@echo "Building the SMI Server image..."

	@echo "Listing the current docker version..."
	docker version

	@echo "Changing to SMI root directory..."
	cd ${PEGASUS_SMI_ROOT}
	
	docker build --tag ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION} .

docker-push-server-image:
	@echo "Pushing the built SMI Server image to private image registry..."

	docker tag ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION} ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}
	docker push ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}

# Subtargets for clean
clean-build:
	@echo "Cleaning the build container..."

	@echo "Changing to pegasus root directory..."
	cd ${PEGASUS_ROOT}

	@echo "Cleaning the build..."
	make clobber
	make clean

docker-clean-images: docker-remove-server-images \
			  		 docker-remove-build-image

docker-remove-build-image:
	@echo "Removing build image..."
	
	docker rmi ${DOCKER_REGISTRY}/${BUILD_IMAGE}:${BUILD_IMAGE_VERSION}

docker-remove-server-images:
	@echo "Removing server images..."
	
	@echo "Removing the repository tagged server image..."
	docker rmi ${DOCKER_REGISTRY}/${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}

	@echo "Removing the server image..."
	docker rmi ${SERVER_IMAGE}:${SERVER_IMAGE_VERSION}

