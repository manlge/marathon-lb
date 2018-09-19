GO=go
BUILDFLAGS=-a -installsuffix cgo -ldflags '-w -s'

PREFIX?=$(shell pwd)

# You can change that to your app name.
TARGET=target

DIST_FILE="$(TARGET).tar.gz"

DOCKER_IMAGE_PREFIX=cloud
DOCKER_IMAGE_TAG=$(DOCKER_IMAGE_PREFIX)/$(TARGET)

.PHONY: all build clean test dist run vendor build-linux-amd64 build-linux-i386 build-darwin docker-image-linux-amd64
.DEFAULT: build
.DEFAULT_GOAL := build

all: build test dist

build-linux-amd64:
	@echo "+ $@"
	GOOS=linux GOARCH=amd64	CGO_ENABLED=0 $(GO) build $(BUILDFLAGS) -o "$(PREFIX)/$(TARGET)-linux-amd64"

build-linux-i386:
	@echo "+ $@"
	GOOS=linux GOARCH=386 CGO_ENABLED=0	$(GO) build $(BUILDFLAGS) -o "$(PREFIX)/$(TARGET)-linux-i386"

build-darwin:
	@echo "+ $@"
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 $(GO) build $(BUILDFLAGS) -o "$(PREFIX)/$(TARGET)-darwin"

# 用于开发过程中进行构建，速度较快，但cgo不会静态编译，运行期存在依赖
build:
	@echo "+ $@"
	$(GO) build -o "$(PREFIX)/$(TARGET)"

# docker一般运行于amd64 Linux，目前只提供该系统docker镜像构建
docker-image-linux-amd64: build-linux-amd64
	@echo "+ $@"
	docker build -t $(DOCKER_IMAGE_TAG) .
ifeq ($(PUSH),true)
	docker push $(DOCKER_IMAGE_TAG)
endif

clean:
	@echo "+ $@"
	@$(GO) clean
	@rm -rf "$(PREFIX)/$(TARGET)" "$(PREFIX)/$(TARGET)"-* lastupdate.tmp $(DIST_FILE)

test:
	@echo "+ $@"
	@$(GO) test ./...

dist: build-linux-amd64 build-linux-i386 build-darwin
	@echo "+ $@"
	tar czf $(DIST_FILE) $(TARGET)-* conf

run:
	@echo "+ $@"
	@echo "Launching with config: conf/app.conf"
#	@cat conf/app.conf
	@sh -c "bee run"

vendor:
	@echo "+ $@"
	@govendor add +external

generate-docs:
	@bee generate docs
