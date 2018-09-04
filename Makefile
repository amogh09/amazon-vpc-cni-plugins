# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

# Build paths.
ROOT := $(shell pwd)
SRC_DIR = .
BIN_DIR = ./bin
SOURCES := $(shell find $(SRC_DIR) -name '*.go')

# Plugin binaries.
VPC_BRANCH_ENI_PLUGIN_BINARY = $(BIN_DIR)/vpc-branch-eni
VPC_BRANCH_PAT_ENI_PLUGIN_BINARY = $(BIN_DIR)/vpc-branch-pat-eni

# Git repo version.
VERSION ?= $(shell git describe --tags --always --dirty)
GIT_SHORT_HASH ?= $(shell git rev-parse --short HEAD 2> /dev/null)
GIT_PORCELAIN ?= $(shell git status --porcelain 2> /dev/null | wc -l)

# If we can't inspect the repo state, fall back to safe static strings.
ifeq ($(strip $(GIT_SHORT_HASH)),)
	GIT_SHORT_HASH=unknown
endif
ifeq ($(strip $(GIT_PORCELAIN)),)
	# This indicates that the repo is dirty.
	GIT_PORCELAIN=1
endif

.PHONY: build
build: plugins unit-test

.PHONY: plugins
plugins: vpc-branch-eni vpc-branch-pat-eni

.PHONY: vpc-branch-eni
vpc-branch-eni: $(VPC_BRANCH_ENI_PLUGIN_BINARY)

.PHONY: vpc-branch-pat-eni
vpc-branch-pat-eni: $(VPC_BRANCH_PAT_ENI_PLUGIN_BINARY)

$(VPC_BRANCH_ENI_PLUGIN_BINARY): $(SOURCES)
	GOOS=linux CGO_ENABLED=0 go build -installsuffix cgo -a -ldflags "\
		-X github.com/aws/amazon-vpc-cni-plugins/version.GitShortHash=$(GIT_SHORT_HASH) \
		-X github.com/aws/amazon-vpc-cni-plugins/version.GitPorcelain=$(GIT_PORCELAIN) \
		-X github.com/aws/amazon-vpc-cni-plugins/version.Version=$(VERSION) -s" \
		-o ${ROOT}/${VPC_BRANCH_ENI_PLUGIN_BINARY} github.com/aws/amazon-vpc-cni-plugins/plugins/vpc-branch-eni
	@echo "Built vpc-branch-eni plugin"

$(VPC_BRANCH_PAT_ENI_PLUGIN_BINARY): $(SOURCES)
	GOOS=linux CGO_ENABLED=0 go build -installsuffix cgo -a -ldflags "\
		-X github.com/aws/amazon-vpc-cni-plugins/version.GitShortHash=$(GIT_SHORT_HASH) \
		-X github.com/aws/amazon-vpc-cni-plugins/version.GitPorcelain=$(GIT_PORCELAIN) \
		-X github.com/aws/amazon-vpc-cni-plugins/version.Version=$(VERSION) -s" \
		-o ${ROOT}/${VPC_BRANCH_PAT_ENI_PLUGIN_BINARY} github.com/aws/amazon-vpc-cni-plugins/plugins/vpc-branch-pat-eni
	@echo "Built vpc-branch-pat-eni plugin"

.PHONY: unit-test
unit-test: $(SOURCES)
	go test -v -cover -race -timeout 10s ./...

.PHONY: integration-test
integration-test: $(SOURCES)
	go test -v -tags integration -race -timeout 10s ./...

.PHONY: clean
clean:
	rm -rf ${ROOT}/bin ||:
