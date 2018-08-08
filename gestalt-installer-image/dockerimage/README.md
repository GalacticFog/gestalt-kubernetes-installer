
# Gestalt Kubernetes Install (Docker Image)

## dependencies
* kubectl (downloaded from internet)
* gestalt-cli (project must exist in same parent directory of this project)

## Prerequisites - Build gestalt-cli

```sh
git clone git@gitlab.com:galacticfog/gestalt-cli.git

cd gestalt-cli

sbt clean update compile assembly
```


## Build and Publish Docker Image

1) Fetch dependencies to pull down `kubectl` into the `deps` directory, as well as the Gestalt Platform CLI

```sh
./fetch-deps.sh
```

2) Build and Publish Docker Image

```sh
# 'latest' tag
./build_and_publish.sh latest

# Or, a release tag
./build_and_publish.sh kube-1.0.0
```

## Re-fetch dependencies
Refetch dependencies if a dependency is updated (e.g. `gestalt-k8s-install` project was updated)

```sh
# Refetch
./clean-deps.sh && ./fetch-deps.sh

#rebuild
./build_and_publish.sh latest
```
