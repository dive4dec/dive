# Portable Notebook Containers DIVE for DEC

This repository contains dockerfiles to build Jupyter notebook images for the [DIVE](https://github.com/dive4dec/dive4dec.github.io) virtual learning environment. The dockerfiles are divided into modules and folders, so that different features can be stacked together to build a custom docker image for different courses.

## Prerequisites

- **Linux system** with *bash*, *git*, and *make*. E.g.,
  - [Ubuntu.](https://ubuntu.com/)
- **Docker** for building docker images. E.g.,
  - [install on Ubuntu.](https://docs.docker.com/engine/install/ubuntu/)
- **Docker registry** access to push docker images. E.g.,
  - *public registry* like [dockerhub](https://hub.docker.com/), or
  - *private registry* for a Kubernetes cluster such as [microk8s](https://microk8s.io/docs/registry-built-in).

## Build/run an image

*Clone the repository* by running the following shell command in a directory of your choice:

```
git clone https://github.com/dive4dec/dive.git
```

To *build and run the jupyter notebook image supporting different programming languages* (C++, Java, SQL, LaTeX, ...), run the following command under the root folder of the cloned repository:

```
make programming
```

After the build completes, the image, called `programming` (or `programming:latest`) will run as a container serving a JupyterLab App. Access the *url* printed to the terminal:

```
...
Jupyter Server 1.18.1 is running at:
...
 or http://127.0.0.1:8888/lab?token=ec28c6a0454167bbf8f038695c58ab8fd297f9e26e3ffc0e
...
```

Try out some example notebooks in the `work` directory. You can terminate the App from the terminal as usual, e.g., by pressing `Ctrl+C`. If the image fails to build/run, open the [`Makefile`](./Makefile) under the root folder to check/modify the commands under `programming`:

```
...
programming:
	docker build \
		-t "programming" -f programming/Dockerfile .
	docker run --rm -it  -p 8888:8888/tcp -v "$$(pwd)/programming/examples":/home/jovyan/work programming
...
```

If you already have the right to run the docker commands `docker build`/`run`, e.g., you are in the `docker` group or have `root` access, then you may need to further check/modify the file `programming/Dockerfile` to resolve version conflicts among different packages.

## Build/run a custom image

You can build a custom image by stacking the dockerfiles in a pile. As an example, check the `main` job at the beginning of the Makefile:

```
# main image to deploy
main:
	base=jupyter/scipy-notebook; i=0; \
	for module in jupyter-interface programming math dev; \
    ...
```

Running `make main` will build
- `jupyter-interface/Dockfile` first as the base image `main1_jupyter-interface`, followed by
- `programming/Dockfile` as `main2_programming`,
- `math/Dockfile` as `main3_dev`, and
- `dev/Dockfile` as `main4_dev`, 

which gets further tagged as `main` because `main4_dev` is the final-stage build.
For the image to be deployed for others to use, you should push the image to a registry by

```
make push-main
```

after specifying the registry and version at the beginning of the Makefile:

```
...
# Registry for docker images
REGISTRY=localhost:32000
# version for tagging image for deployment
VERSION=0.0.2
```

The image will receive the tag `"${REGISTRY}/main:${VERSION}"` for others to pull the image.

You may also want to create a new module or rename an existing one. Make sure you add the new name to `modules` defined at the end of the Makefile:

```
...
modules := main scipy-nv programming divedeep jupyter-interface math datamining grading deploy classic push
...
```