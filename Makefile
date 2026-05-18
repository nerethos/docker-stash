IMAGE   := nerethos/stash-jellyfin-ffmpeg
VERSION := $(shell cat UPSTREAM_VERSION)

.PHONY: help build build-lite test test-lite push push-lite

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the full image tagged :latest and :<version>
	docker build --build-arg STASH_RELEASE=$(VERSION) \
	  -t $(IMAGE):$(VERSION) -t $(IMAGE):latest \
	  -f Dockerfile .

build-lite: ## Build the lite image tagged :lite and :lite-<version>
	docker build --build-arg STASH_RELEASE=$(VERSION) \
	  -t $(IMAGE):lite-$(VERSION) -t $(IMAGE):lite \
	  -f Dockerfile.lite .

test: ## Build the full image tagged :testing (uses layer cache)
	docker build --build-arg STASH_RELEASE=$(VERSION) \
	  -t $(IMAGE):testing \
	  -f Dockerfile .

test-lite: ## Build the lite image tagged :testing-lite (uses layer cache)
	docker build --build-arg STASH_RELEASE=$(VERSION) \
	  -t $(IMAGE):testing-lite \
	  -f Dockerfile.lite .

push: build ## Build and push the full image
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest

push-lite: build-lite ## Build and push the lite image
	docker push $(IMAGE):lite-$(VERSION)
	docker push $(IMAGE):lite
