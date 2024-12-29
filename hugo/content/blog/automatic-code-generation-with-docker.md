+++
title = "Automating Code Generation With Docker"
date = "2019-04-11T04:21:57+01:00"
+++

Code generation can be really useful; need to generate some models from an OpenAPI spec or a Protocol Buffer definition? No problem! Unfortunately in a team environment this can pose a few problems though: What happens when new members of staff join the team and have newer versions of the generation tools? Should generated files be checked in source control - and if so, how can you ensure that no manual modifications are present?

### Introducing the utility Docker image

I'm a *big fan* of utility images; small Docker images that contain the tools to carry out a certain task - i.e `aws-cli` and `kubectl` for infrastructure tasks. Need to get someone up to speed with a *Kubernetes* task? Check they've got the relevant credentials, get them to do a `docker run -it --entrypoint=/bin/sh {image}` and - *bang* - they've got everything they need.

So let's go about configuring one that is capable of generating protocol buffer messages and OpenAPI models. To save some time we're going to use an existing image which contains the `protoc` tool - [`nanoservice/protobuf`](https://hub.docker.com/r/nanoservice/protobuf). We'll extend this image to include `go-swagger`, our swagger code generation tool, and `make`, which we'll use for build definition and execution.

To add the tools we require - `go-swagger` and `make` - our Dockerfile will end up looking something like this:

```
FROM nanoservice/protobuf

MAINTAINER Fergus In London <fergus@fergus.london>
ARG GITHUB_URL="https://api.github.com/repos/go-swagger/go-swagger/releases/latest"

# Install make, the go tooling, and any build dependencies
RUN apk add --update make curl jq bash git make musl-dev go

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

# protoc actually requires language specific generators; so we're
#  opting for `protoc-gen-go`.
RUN go get -u github.com/golang/protobuf/protoc-gen-go

# Download Swagger Binary and configure for execution in the $PATH
RUN curl -o swagger -L `curl -s $GITHUB_URL | jq -r '.assets[] | select(.name | contains("'"$(uname | tr '[:upper:]' '[:lower:]')"'_amd64")) | .browser_download_url'`
RUN mv swagger /usr/local/bin/swagger
RUN chmod +x /usr/local/bin/swagger

# Remove build specific packages
RUN apk del curl jq
ENTRYPOINT ["make"]

```

At under 15 lines of code when comments and blank lines are removed, this Dockerfile is incredibly simple - but still packs all the tools we need.

```
➜  docker build -t codegen-demo .
Sending build context to Docker daemon  3.072kB
   [ ... ]
Successfully built 16173b2e6aef
Successfully tagged codegen-demo:latest
➜  docker run -it --entrypoint=/bin/bash codegen-demo
bash-4.3# swagger
Please specify one command of: expand, flatten, generate, init, mixin, serve, validate or version
bash-4.3# protoc
Missing input file.
bash-4.3# make
make: *** No targets specified and no makefile found.  Stop.
bash-4.3# exit
➜
```

### Simple Makefile

With the utility Docker image configured with all the required tools, we simply need to write a `Makefile` that specifies two different tasks:

1. (*On the host*) The build of the utility image from our Dockerfile, and the subsequent execution of the resulting image;
2. (*On the container*) The execution of our generators with the correct CLI flags and configuration.

Although you could argue that a better practice would involve using two different `Makefile`s - one for the container and one for the host - for the sake of simplicty I've opted for one. The skeleton of this container looks like this:

```
WORKSPACE_DIRECTORY = "/workspace"
UTILITY_CONTAINER = "codegen-demo"
CONTAINER_MAKE_TARGET = "generator"

# Run our image with the current directory mounted to a workspace directory on the
#  container, and then execute our make target.
execute:
	@docker run -t -v `pwd`:${WORKSPACE_DIRECTORY} -w ${WORKSPACE_DIRECTORY} ${UTILITY_CONTAINER} ${CONTAINER_MAKE_TARGET}

generate-protobuf:
	@echo "protobuf - implementation is project specific"

generate-swagger:
	@echo "swagger - implementation is project specific"

generator: generate-protobuf generate-swagger
```

Like the `Dockerfile` it's very simple, but also like the `Dockerfile`, it's perfectly functional.

```
➜  make
protobuf - implementation is project specific
swagger - implementation is project specific
➜
```

**If you want to see a working example then take a look at the repository on github - [`fergusinlondon/codegen-demo`](https://github.com/FergusInLondon/docker-codegen-demonstration).** Pay specific attention to the [`Makefile`](https://github.com/FergusInLondon/docker-codegen-demonstration/blob/master/Makefile) and [`Dockerfile`](https://github.com/FergusInLondon/docker-codegen-demonstration/blob/master/Dockerfile), and then try and run it - this is as simple as cloning the repository and typing `make`!

## Wrapping up

Not only is the use of a utility Docker image incredibly simple, but it's also *very useful* when trying to ensure consistencies in tooling amongst team members.

Beyond this use-case though, there's other times where this technique could be prove helpful - such as:

1. When using monorepositories, where models may be stored in one package, whilst the definitions are stored in another package.
2. During CI processes, preventing the need for engineers to commit their automatically generated files in to source control.

Whilst the demonstration repository is lightweight, it successfully abstracts all the configuration and installation of these generation tools in to one isolated container, and ultimately would be functional enough for real world projects where *Protocol Buffers* and *Swagger API definitions* are in use.
