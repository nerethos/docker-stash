version=v0.26.1
.PHONY: build-prod
build-prod:
	docker build --pull --no-cache -t nerethos/stash-jellyfin-ffmpeg:latest -t nerethos/stash-jellyfin-ffmpeg:${version}  -f ./Dockerfile .

.PHONY: push-prod
push-prod: build-prod
	docker push nerethos/stash-jellyfin-ffmpeg:${version}
	docker push nerethos/stash-jellyfin-ffmpeg:latest