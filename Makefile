SHELL:= /bin/bash
# Registry for docker images
REGISTRY=localhost:32000
# REGISTRY=chungc
# version for tagging image for deployment
VERSION=0.0.2

# main image to deploy
main:
	base=jupyter/scipy-notebook; i=0; \
	for module in jupyter-interface programming math dev; \
	do \
	stage="main$$((++i))_$$module"; \
	docker build --build-arg BASE_CONTAINER="$$base" \
		-t "$$stage" -f "$$module/Dockerfile" .; \
	base="$$stage"; \
	done; \
	docker tag "$$stage" main
	docker run --rm -it  -p 8888:8888/tcp main

push-%:
	docker tag "$*" "${REGISTRY}/$*:${VERSION}"
	docker push "${REGISTRY}/$*:${VERSION}"

# Scipy notebook with GPU support (Nvidia CUDA)
scipy-nv:
	docker build \
		--pull \
		--build-arg ROOT_CONTAINER="nvidia/cuda:11.2.2-cudnn8-runtime-ubuntu20.04" \
		--build-arg PYTHON_VERSION="3.9" \
		-t "base-notebook-nv" docker-stacks/base-notebook
	docker build \
		--build-arg BASE_CONTAINER="base-notebook-nv" \
		-t "minimal-notebook-nv" docker-stacks/minimal-notebook
	docker build \
		--build-arg BASE_CONTAINER="minimal-notebook-nv" \
		-t "scipy-nv" docker-stacks/scipy-notebook

# Support different programming languages in addition to python such as
# C++, Java, SQL, javascript, typescript, ...
programming:
	docker build \
		-t "programming" -f programming/Dockerfile .
	docker run --rm -it  -p 8888:8888/tcp -v "$$(pwd)/programming/examples":/home/jovyan/work programming

# Support different interfaces such as
# VSCode, remote desktop, retrolab, ...
jupyter-interface:
	docker build --pull \
		-t "jupyter-interface" -f jupyter-interface/Dockerfile .
	docker run --rm -it  -p 8888:8888/tcp -v "$$(pwd)/jupyter-interface/examples":/home/jovyan/work jupyter-interface


# Tools for grading notebooks
grading:
	docker build --pull \
		-t "grading" -f grading/Dockerfile .
	docker run --rm -it  -p 8888:8888/tcp -v "$$(pwd)/grading/examples":/home/jovyan/work grading bash -c \
		"cp work/nbgrader_config nbgrader_config.py && start-notebook.sh"


# Tools for datamining and machine learning such as
# Weka, tensorflow, pytorch, R, ...
# Use scipy-nv for GPU support
datamining: scipy-nv
	base=scipy-nv ; i=0; \
	for module in jupyter-interface datamining; \
	do \
	stage="main$$((++i))_$$module"; \
	docker build --build-arg BASE_CONTAINER="$$base" \
		-t "$$stage" -f "$$module/Dockerfile" .; \
	base="$$stage"; \
	done; \
	docker tag "$$stage" datamining
	docker run --rm -it  -p 8888:8888/tcp datamining

# Tools for mathematics
math:
	docker build --pull \
		-t "math" -f math/Dockerfile .
	docker run --rm -it  -p 8888:8888/tcp math

# Deployment
# This is intended for private use.
deploy: scipy-nv
	cd DIVE-deploy; \
	docker build --pull \
				 --build-arg ROOT_CONTAINER=scipy-nv \
				 -t "deploy" -f Dockerfile .

divedeep: scipy-nv
	base=scipy-nv ; i=0; \
	for module in jupyter-interface programming datamining grading dev; \
	do \
	stage="divedeep$$((++i))_$$module"; \
	docker build --build-arg BASE_CONTAINER="$$base" \
		-t "$$stage" -f "$$module/Dockerfile" .; \
	base="$$stage"; \
	done; \
	docker tag "$$stage" divedeep
	cd dive-deploy; \
	docker build \
		--build-arg BASE_CONTAINER="divedeep" \
		-t "${REGISTRY}/divedeep:${VERSION}" -f Dockerfile .
	docker push "${REGISTRY}/divedeep:${VERSION}"
	docker run --rm -it  -p 8888:8888/tcp "${REGISTRY}/divedeep:${VERSION}"


modules := main scipy-nv programming divedeep jupyter-interface math datamining grading deploy classic push

.PHONY: $(modules)