# JESI.IO
## Build-Bus

A single docker container for building and testing all of our projects; and for cancelling redundant builds on CircleCI 
using [https://github.com/jesims/circleci-tools](https://github.com/jesims/circleci-tools).

## Docker Hub

This container is automatically built and made available by DockerHub at [https://hub.docker.com/r/jesio/build-bus](https://hub.docker.com/r/jesiio/build-bus) and can be
referenced in the CircleCI `config.yml` by using `jesiio/build-bus:latest`. For example:

```yml
aliases:
  cmds:
    submodule_update: &SUBMODULE_UPDATE
      run:
        name: Git Submodule Update
        command: 'git submodule sync && git submodule update --init'
    cancel_redundant: &CANCEL_REDUNDANT
      run:
        name: Check & Cancel Redundant Build
        command: 'cancel-redundant-builds.sh'

jobs:
  deps:
    docker: 
      - image: jesiio/build-bus:latest
    steps:
      - *CANCEL_REDUNDANT
      - checkout
      - *SUBMODULE_UPDATE
      - ...
```

### Manual Build and Deploy

A manual build and deploy (to DockerHub) can be run by invoking `./deploy.sh`

## Testing

To ensure the build runs, invoke the provide `test.sh` script. 

## Contains

* Node.js
* Clojure and Clojurescript
* Maven
* Leiningen
* PhantomJS
* AWS CLI/AWS EB CLI

