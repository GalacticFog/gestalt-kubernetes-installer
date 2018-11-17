# Gestalt Installer Base Image

The `installer-base-image` submodule of the `gestalt-kubernetes-installer` generates a container image which
serves as a base image for the `gestalt-installer-image` container.  This image builds from the Alpine Linux
OS image plus updarted packages, and adds all the command-line tools and utilities the installer needs to deploy
Gestalt to a Kubernetes cluster which are not in themselves part of the installer scripts.

This module should not need to be updated in lock-step with `gestalt-installer-image`.  We can therefore make
changes to the installer scripts and resources without also updating the base OS, tools and packages stored in
the base image. This keeps the installer image layer for each new installer version much lighter, and iterative
imstaller image builds run faster.  We need only update the base image when we need to update the command-line 
tools, installed packages, or the underlying OS.

## Building a new installer base image

Run the `build.sh` script to build a new installer base image.

### 1. Dependencies

You'll need the *bash shell* installed at `/bin/bash`, which should already be available on a MacOS or
Linux system.

You'll also need *a local docker install* on your `$PATH`. If you don't already have docker installed, try
[Docker CE](https://docs.docker.com/install/).

The build script also depends upon the `grep` and `awk` command-line utilities, which are generally
pre-installed with MacOS, all Unix variants and most Lunix distributions.

But that's about it!  Since most of the more complex work of building the base installer image runs within 
a builder container, most of the dependencies that would normally be needed to complete the build are loaded
in builder stage, which keeps build script dependencies to a minimum.

### 1. Using `build.sh`

Just run it!  When run without any parameters, the build script uses the default values defined at the top of
the script, as described in the usage guide below.

```
-> ./build.sh -h

build.sh USAGE:
    build.sh [-p] [-r REGISTRY] [-t TAG] [-l LABEL]
    
    OPTIONS:
    -p
      Push the built image to the container image registry (default false)
    -r REGISTRY
      Push the built image to this registry (default DockerHub 'galacticfog' registry)
    -l LABEL
      Use this image label value (default 'gestalt-installer-base')
    -t TAG
      Publish the image with this tag value. Can be used multiple times. (default 'testing')
```

*Note:* _You can view the usage guide anytime by invoking the script with the `-h` flag._

The `-p` option is false by default to prevent accidental release of an image during testing or development.
You *must* set this flag if you want to push the container image to the registry after building.

By default, the build script tags the built image with the default values described above.  It sets only
one tag tag on the built image, and the default tag above is always applied to the image during the build,
even if you also set other tags.  However, if you specify any tags using the `-t` option, the script will 
push only the specified tags to the registry, and will not push the default tag (unless the default tag is
also set explicitly using the `-t` option.

You can set the `-t` option multiple times to tag the built image with multiple tags.  

```
# EXAMPLES

# Tag BUT DO NOT PUSH the image as "some.other.registry.io/galacticfog/different-image-name:alternate-tag"
> ./build.sh -r "some.other.registry.io/galacticfog" -l "different-image-name" -t "alternate-tag"

# Tag and push the image as "reg/image:tag1", "reg/image:tag2" and "reg/image:tag3"
> ./build.sh -p -r reg -l image -t tag1 -t tag2 -t tag3

# Tag and push the image as "galacticfog/gestalt-installer-base:testing"
> ./build.sh -p

# Tag and push the image as "galacticfog/gestalt-installer-base:testing" and ":latest" and ":v1"
> ./build.sh -p -t testing -t latest -t v1

```

### 2. Using `download_cli_tools.sh`

This module's `Dockerfile` builds the `gestalt-installer-base` image using a 
[multi-stage build process](https://docs.docker.com/develop/develop-images/multistage-build/).
In the first stage, it launches a _*builder*_ container, which downloads and
extracts all the resources the target image needs.  Then in the second stage, it copies all the finished
resources into a _*target*_ container image, which in this case is the base installer image.  Once all the 
stages are complete, the builder container has served its purpose and can be discarded.

This module's builder container runs the `download_cli_tools.sh` script, which downloads and extracts 
`kubectl`, `helm` and `fog` CLI executable binaries from their respective release site.  Docker then copies 
the tools it downloaded into the installer container,

The `download_cli_tools.sh" script is therefore designed to run within an Alpine Linux container and not
within your local OS.  It downloads CLI tool versions built for Alpine Linux running on a 64-bit AMD
processor.  If you are running a different OS on a different processor, those versions will most likely 
refuse to run on your PC directly.  You can still run the script locally if you like, but when it runs
the downloaded CLI tools to check their versions, those commands will fail.

However, you can use docker to create and run the builder container _without_ also building the
base installer container image, and that's the most convenient way to test the download script.

```
# Build and run the first-stage builder container only
> docker build . --target=builder
```

The script prints diagnostic output messages to indicate the versions the script will try to download for 
each CLI tool, the URL from which the script will download each tool, and the actual downloaded versions.

```
#
# Plenty of output before these messages reporting the versions it will try to install
#
----- Setting FOG_VERSION to '0.10.2' -----
----- Setting HELM_VERSION to 'latest' -----
----- Setting KUBECTL_VERSION to 'latest' -----
#
# Then the download URL for kubectl, followed by the output of `kubectl version --client`
#
Downloading kubectl version v1.12.2 from 'https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/linux/amd64/kubectl'
{Client Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.2", GitCommit:"17c77c7898218073f14c8d573582e8d2313dc740", GitTreeState:"clean", BuildDate:"2018-10-24T06:54:59Z", GoVersion:"go1.10.4", Compiler:"gc", Platform:"linux/amd64"}
#
# Next, the download URL for helm and the output of `helm version -c`
#
Downloading helm version v2.11.0 from 'https://kubernetes-helm.storage.googleapis.com/helm-v2.11.0-linux-amd64.tar.gz' to './helm.tar.gz'
Client: &version.Version{SemVer:"v2.11.0", GitCommit:"2e55dbe1fdb5fdb96b75ff144a339489417b146b", GitTreeState:"clean"}
#
# Finally, the download URL for the fog CLI, output from the unzip command, and the output of `fog --version`
#
Downloading fog CLI version 0.10.2 from 'https://github.com/GalacticFog/gestalt-fog-cli/releases/download/0.10.2/gestalt-fog-cli-alpine-0.10.2.zip' to './fog.zip'
0.10.2
#
# And so on...
#
```

If successful, docker will display the SHA hash ID of the builder container image.

```
Command-line tools successfully downloaded!
Removing intermediate container b223412a605b
 ---> a3152a548a96
Successfully built a3152a548a96
```

You should then be able to list and remove the builder container image to clean up,

```
# List the built container images
#
> docker images
# or
> docker image list
REPOSITORY                                  TAG                 IMAGE ID            CREATED             SIZE
<none>                                      <none>              a3152a548a96        24 minutes ago      392MB
#
# Plus whatever other images you have loaded to your local docker engine below

# You can then clean up by removing the builder image and run again as many times as you like
> docker image rm a3152a548a96
Deleted: sha256:a3152a548a96e4fb6eb02f60e5e2cc14ee6c2a53743d66e7338c982fc5867f35
#
# Plus all the interim image layers created to make the builder image
```

You can also run the docker build without setting a target, in which case docker will build both the builder and
base installer container images.  You'll see all the same output as above without the final `Successfully built X`
line, plus the output from the second stage.

The RUN command in the second stage also invokes each CLI tool to report the installed version, as well as the
SHA hash ID of the built base installer container image.

```
Client Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.2", GitCommit:"17c77c7898218073f14c8d573582e8d2313dc740", GitTreeState:"clean", BuildDate:"2018-10-24T06:54:59Z", GoVersion:"go1.10.4", Compiler:"gc", Platform:"linux/amd64"}
Client: &version.Version{SemVer:"v2.11.0", GitCommit:"2e55dbe1fdb5fdb96b75ff144a339489417b146b", GitTreeState:"clean"}
0.10.2
Removing intermediate container bbcc03d100d8
 ---> a8b5b6ae0bf5
Successfully built a8b5b6ae0bf5
```

You should see both the builder and base installer container images when you list loaded docker images.

```
# List the built container images
#
> docker images
REPOSITORY                                  TAG                 IMAGE ID            CREATED             SIZE
<none>                                      <none>              a8b5b6ae0bf5        9 minutes ago       392MB
<none>                                      <none>              ae380a4f39a5        9 minutes ago       392MB
#
# Plus all the other loaded images.
#
# Delete these images with the docker image rm command.
> docker image rm a8b5b6ae0bf5 ae380a4f39a5
```

Of course, if you run the docker build command yourself it won't tag or push the built images for you, but
that's what the `build.sh` script is for!

### 3. Setting default registry, image label and image tag values

The default values for tagging and pushing the image are defined at the top of `build.sh` - change them if you must.

### 4. Changing CLI tool versions

_*Keep in mind*_ that the default `kubectl` and `helm` versions are both set to `latest`.  The download script will
therefore download the newest versions of those CLI tools for each new base installer container image build, unless
you specify another version.  _We don't currently have a means to get the latest build version number for the `fog`
CLI tool._

You can change the CLI tool versions the builder downloads by altering the default ENV variable values
at the top of the `Dockerfile`.  If you are updating to a newer version and plan to use it
going forward, changing the default values will ensure that future base installer container
image builds won't use an older version.

```
# The builder stage ARG and ENV rules look like this in the Dockerfile.
#
ARG fog_version
ARG helm_version
ARG kubectl_version
ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl" \
    fog_version=${fog_version:-0.10.2} \
    helm_version=${helm_version:-latest} \
    kubectl_version=${kubectl_version:-latest}

# ARG variables can be set by the --build-arg parameter to the docker CLI tool, and override the
# default ENV variable values if the referenced ARG variable is not null.
#
# You change the default ENV var values by altering the part after the ":-" in the variable declaration.
#
ENV ENV_VAR_NAME=${ARG_VAR_NAME:-default_value} \
    fog_version=${fog_version:-CHANGE_DEFAULT_VALUE_HERE} \
    helm_version=${helm_version:-CHANGE_DEFAULT_VALUE_HERE} \
    kubectl_version=${kubectl_version:-CHANGE_DEFAULT_VALUE_HERE}
```

### *TODO* _add an option in the `build.sh` script to set docker `--build-arg` values and/or override these defaults._

You can also override the default CLI tool versions when building with the `docker build` command directly by setting 
`--build-arg` parameters to match the `ARG` rules defined in the `Dockerfile`.

```
# Build an installer base image with these CLI tool versions
#
> docker build --build-arg fog_version="0.9.2" --build-arg kubectl_version="v1.12.1" --build-arg helm_version="v2.10.0-rc.3"
```

## Tagging the installer base image

If you're only using the installer image on your local system, you can apply whatever tags that suit your
purposes.  However, if you're planning to share the new base image with others, please follow these 
guidelines.

### *TODO* _write some guidelines_
We could automate a versioning scheme using a file to store the most recent version and automatically iterate
the last-significant digit in `build.sh` before adding it to the TAGS list.

## Pushing the base installer image to a registry

Set the `-p` flag when calling the `build.sh` script to tell it to upload the built base installer container
image to the configured container registry.  It will automatically push the image for each tag defined with the
`-t` option on the command-line, or the default tag only if no other tag has been set.

### *TODO* _maybe it should refuse to push the tagged image unless the user sets a tag explicitly?_

