# Wait For DB Container Image

The `wait-for-db` container image can be added as an `initContainer` to a Kubernetes
Deployment spec to delay the main containers from launching until after the Postgres
database is accepting connections, and optionally until a given database has been
created.

The initContainer will use the `pg_isready` utility to check whether the target Postgres 
server is accepting connections.  Once it starts accepting connections, it will then use
the `psql` utility to connect to Postgres and list the available databases.  If it finds
the desired database, it exits successfully.

## Configuring an initContainer

To wait only for Postgres to begin accepting connections, set `PGHOST` and `PGPORT`
environment variables, but *DO NOT* set the `PGDATABASE` environment variable.

```
      initContainers:
      - name: 'wait-for-db'
        image: {{ .Values.db.waitImage | quote }}
        imagePullPolicy: {{ .Values.common.imagePullPolicy | quote }}
        env:
        - name: 'PGHOST'
          value: {{ template "gestalt.dbHost" . }}
        - name: 'PGPORT'
          value: {{ template "gestalt.dbPort" . }}
```

To also wait for the necessary database to be created, set `PGDATABASE`, `PGUSER` and
`PGPASS` environment variables in addition to the `PGHOST` and `PGPORT` environment
variables above.  You can also set the `PGCONNECT_TIMEOUT` environment variable to 
control the `psql` utility's connection timeout period.

```
      initContainers:
      - name: 'wait-for-db'
        image: {{ .Values.db.waitImage | quote }}
        imagePullPolicy: {{ .Values.common.imagePullPolicy | quote }}
        env:
        - name: 'PGHOST'
          value: {{ template "gestalt.dbHost" . }}
        - name: 'PGDATABASE'
          value: {{ .Values.meta.databaseName | quote }}
        - name: 'PGPASS'
          valueFrom:
            secretKeyRef:
              name: {{ template "gestalt.secretsName" . }}
              key: 'db-password'
        - name: 'PGUSER'
          valueFrom:
            secretKeyRef:
              name: {{ template "gestalt.secretsName" . }}
              key: 'db-username'
        - name: 'PGPORT'
          value: {{ template "gestalt.dbPort" . }}
        - name: 'PGCONNECT_TIMEOUT'
          value: '3'
```

Keep in mind that the main container will not launch until the initContainer has
existed successfully.  If the main container creates the database that the initContanier
is waiting for, it will wait forever!

## Building and Deploying The Wait-For-DB Image

This `gestalt-wait-for-db` module includes a `build.sh` script for building the
image and automatically pushing it to the `gcr.io/galacticfog-public/gestalt`
image registry.

### TL;DR build

All the default values are set to build and push the `wait-for-db` image for the usual case.
To build and deploy the current code, just run...
```sh
./build.sh
```

You can change the target container image repository, the image label or tags, and build
the image with a different default tag using the command-line options described in the 
help screen below.

### build.sh help screen

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
