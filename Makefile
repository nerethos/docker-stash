version=v0.26.1
.PHONY: build
build:
	docker build --pull --no-cache -t nerethos/stash-jellyfin-ffmpeg:latest -t nerethos/stash-jellyfin-ffmpeg:${version}  -f ./Dockerfile .

.PHONY: push
push: build
	docker push nerethos/stash-jellyfin-ffmpeg:${version}
	docker push nerethos/stash-jellyfin-ffmpeg:latest