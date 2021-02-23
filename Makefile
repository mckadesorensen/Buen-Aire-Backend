.SILENT:
.ONESHELL:
.PHONY:

image: Build/buen_aire_backend.Dockerfile
	cd Build && \
	docker build -f buen_aire_backend.Dockerfile -t buen_aire_backend .

container-shell:
	docker run -it --rm \
		--user `id -u` \
		-v ${PWD}:/Buen-Aire-Backend \
		-v ~/.aws:/.aws \
		buen_aire_backend

