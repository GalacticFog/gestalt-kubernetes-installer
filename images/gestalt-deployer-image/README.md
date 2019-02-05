# Building and Deploying GCP Marketplace Install Images

This `gestalt-deployer-images` module includes a `build.sh` script for building the
deployer image and automatically pushing it to the `gcr.io/galacticfog-public/gestalt`
image registry.  It also includes a `republish-images` script for pulling Gestalt 
container images from a source registry, retagging them, and pushing them to the
`gcr.io/galacticfog-public/gestalt` container image registry.

## TL;DR build

All the default values are set to build and push the `deployer` image for the usual case.
To build and deploy the current code, just run...
```sh
./build.sh
```

You can change the target container image repository, the image label or tags, and build
the image with a different default tag using the command-line options described in the 
help screen below.

## TL;DR republish-images

The `republish-images` script executes a dry run by default.  To actually push and pull 
the default list of images with the default pull and push tags, run the script with both 
the `-p` (for pull) and `-P` (for push) flags set.
```sh
./republish-images -p -P
```

Those flags also enable you to pull without pushing or push without pulling - say if you 
want to push an image you've built locally or obtained from another source.

To pull and/or push a single image just use the `-i` option and pass it the name of the
image you want to republish.
```sh
./republish-images -p -P -i gestalt-meta
```

You can also repeat the `-i` option to republish multiple images in a single run.
```sh
./republish-images -p -P -i gestalt-meta -i gestalt-policy -i gestalt-ui-react
```

_*NOTE:*_ The `gestalt-ui-react` image will push to the root `gcr.io/galacticfog-public/gestalt`
registry and _not to a subdirectory_, as Google wishes to treat one of our images as the
parent application.  All the other images push to a subdirectory named for the image being
pushed, i.e. `gcr.io/galacticfog-public/gestalt/gestalt-meta`.

Without additional parameters, the script will pull an image with the `2.4.1` tag and push all 
of the default tags to the target image registry; i.e. `gcp`. `release`, `latest`, `2.4.1`, 
`2.4`, and `2`.  However, you can alter this list either by editing the configuration variables 
at the top of the script, or by using the `-T` option to define a custom set of tags.
```sh
# Without the -p option, the script will push an image from your local registry
./republish-images -P -i gestalt-meta -T some -T silly -T image -T tags
```

Should you need to pull a source image with a different tag, from a different repository,
or to a different target repository, just review the full set of options described below,
or run the script with the `-h` flag to print a help screen.

## build.sh help screen

```
build.sh USAGE:
    build.sh [-p] [-r REGISTRY] [-t TAG] [-l LABEL]
    
    OPTIONS:
    -h
      Print this help info to STDOUT.
    -p
      Push the built image to the container image registry.  If this flag is NOT set, the
      script will build the image, but will not push it to a remote registry. 
      CURRENTLY DEFAULTED TO TRUE!
    -s
      Run silent.  Do not print output to STDOUT, but print errors to STDERR.
    -a BUILD_ARG_NAME=BUILD_ARG_VALUE
      Adds a build-arg to the docker build command.  Can be used multiple times.
    -i
      Print the built image ID to STDOUT even if the -s flag is set.  If both -s and -i
      flags are set, the image ID will be the only output from the build script.
    -v
      Run verbose - print additional diagnostic output to STDOUT.  NOTE: -s overrides -v
      CURRENTLY DEFAULTED TO TRUE!
    -r REGISTRY
      Push the built image to this registry. (default GCP 'gcr.io/galacticfog-public/gestalt' registry)
    -l LABEL
      Use this image label value. (default 'deployer')
    -d DEFAULT_TAG
      Tag the image with this value when building. (default 'latest')
      The default tag will always be applied to the built image, but this tag will NOT be 
      pushed to the registry unless it is also passed in with the -t option
    -t TAG
      Tag and push the image with this value. Can be used multiple times.
      (default tags are "latest", "gcp", "release", "2.4.1", "2.4", and "2")
```

## republish-images help screen

```
republish-images USAGE:
    republish-images [OPTIONS]
    
    OPTIONS:
    -h
      Print this help info to STDOUT.
    -p
      Pull the images from the source image registry.
    -P
      Push the pulled images to the target image registry.
    -r SOURCE_REGISTRY
      Push the built image to this registry. (default DockerHub 'galacticfog' registry)
    -R TARGET_REGISTRY
      Push the built image to this registry. (default Google 'gcr.io/galacticfog-public' registry)
    -i IMAGE
      Adds an image to the list that will be pulled and/or pushed.
    -t SOURCE_TAG
      Pull images with this tag. Can be used multiple times. (default 2.4.1)
    -T TARGET_TAG
      Tag the image with this value. Can be used multiple times. (defaults: latest gcp release 2.4.1 2.4 2)
    -s
      Run silent.  Do not print output to STDOUT, but print errors to STDERR.
    -v
      Run verbose - print additional diagnostic output to STDOUT.  NOTE: -s overrides -v
    -l
      Append the script output to a file for later review. (default ./republish-images.log)
```
