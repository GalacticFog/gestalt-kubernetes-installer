# Installing Gestalt on Google Cloud Platform

This document describes the process for installing and interacting with Galactic Fog's Gestalt platform on 
[Google Cloud Platform](https://cloud.google.com) (GCP).  

## Set Up GCP

Gestalt requires an underlying instance of the [Kubernetes container orchestrator](https://kubernetes.io/) to manage its own
service containers.  You'll want to start by creating a [managed Kubernetes cluster](https://cloud.google.com/kubernetes/) using the 
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) (GKE).

### Create a GCP Account

If you don't already have a GCP account, you can try out Gestalt using a [Free GCP Trial Account](https://console.cloud.google.com/freetrial),
which comes with $300 of free Google credits for the first year.  Those free trial credits should more than cover the Gestalt demo with plenty 
left over to try out other GCP services as well.

Once you'ce completed the signup process, you should see a link that says [Go To Console](https://console.cloud.google.com/getting-started).
That should take you to their [Getting Started](https://console.cloud.google.com/getting-started) page.  Feel free to take the tour before
the next step if you like.  If you create a new project along the way, you can use it for the remaining steps.

### Create a GCP Project

You'll see a big blue navigation bar at the top of the GCP Console page, which is helpfully labeled _Google Cloud Platform_ on the
left side so you won't get lost.

The three horizontal lines to the left of that are the main nagivation menu, which I'll refer to as Main for the rest of this guide.

To the right of the label you should see your project name or _No Project_, with a drop-down triangle just to its right. If you have
not yet created a project, click on the triangle to navigate to the _Select a Project_ dialog and click the _New Project_ link in the
upper-right corner.  Name your new project whatever you like.  I'll refer to it as Project for the rest of this guide.

_*Note*_: If you created your account as an individual, you won't be part of an Organization.  If your account was created for you within
a Google Suite group, your organization name will be listed at the top.  Either is fine.  Feel free to create your project within your
Organization, under No Organization, or without any Organization at all - it should work fine regardless.

### Create a GKE Cluster

Open the _Navigation menu_ (three horizontal lines on the left end of the blue Navigation bar at the top), and scroll down to the 
[_Kubernetes Engine_](https://console.cloud.google.com/kubernetes/list) link.  If you've already created one or more Kubernetes 
clusters, you'll see them listed here.  If this is your first Kubernetes cluster, you'll see a dialog entitled _Kubernetes clusters_
with a _Create Cluster_ button.  Click the button to create a new GKE cluster.

In the _Create a Kubernetes cluster_ dialog, pick the _Standard cluster_ type.  Name it `gestalt-demo` and pick a _Zone_ appropriate
to your location.  Make a note of the _Zone_ value - you'll need that later.

Select the newest _Master version_ - currently *1.10.7-gke.6*.

Increase the number of nodes in the _Node pool_ to 4, and choose a _Machine type_ value of _1 vCPU_.

Click the *Advanced options* link at the bottom of the dialog to display additional cluster creation options.

Scroll down to the _Security_ section and check the _Enable Legacy Authorization_ checkbox.  You can leave all the other options
the same.

Scroll all the way to the bottom and click the *Create* button.

You should now see your new _gestalt-demo_ cluster listed on the _Kubernetes clusters_ page.  It generally takes a while to start
up the new cluster, so now's a good time to take a break and get some coffee.

### Configure Local kubectl to Manage the GKE Cluster

### [Install the Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts)

The [Google Cloud SDK](https://cloud.google.com/sdk/) includes both the [_gcloud_](https://cloud.google.com/sdk/gcloud/) and [_kubectl_ command-line tool](https://kubernetes.io/docs/reference/kubectl/overview/) command-line tools.  Even if you already have _kubectl_ installed, you'll need _gcloud_ to generate an authentication token to connect to your GKE cluster.

If you already have _gcloud_ installed, run this command to update it to the latest version.
`gcloud components update` 

#### Login to GCP with gcloud

This command will create an access token so the _gcloud_ can use your Google user's credentials to connect to GCP.
`gcloud auth login` 

It will open a browser window and propmt you to log in to GCP if you haven't already done so.  You can close the browser window when you're done, and the _gcloud_ tool should then be able to manage your GCP projects.

Run this command with _your project name_ to set it as the default project.
`gcloud config set project [YOUR-PROJECT-NAME]`

Run this command with the _Zone_ in which you created your GKE cluster to set it as the default zone.
`gcloud config set compute/zone [COMPUTE_ZONE]`

Run this command the the _Region_ in which you created your GKE cluster to set it as the default region.
`gcloud config set compute/region [COMPUTE_REGION]`

The region is generally the same as the zone, but with the last dash and letter left off.  For example, if you created your cluster in Zone `us-east1-b`, the region would be `us-east1`.

Run this command to list all your GKE clusters, which should include the new _gestalt-demo_ cluster.
`gcloud container clusters list`

Make sure the status is _RUNNING_.

#### Generate a GCP access token for kubectl

[Configure the local _kubectl_ tool to manage your GKE Kubernetes cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl).

This command wll generate a set of _kubectl_ configurations for your new _gestalt-demo_ cluster.
`gcloud container clusters get-credentials gestalt-demo` 

That will add the access token generated during the GCP login step above to a new user in your local _kubectl_ configuration file, create a new context with the new user and cluster configurations, and switch the _current-context_ to the new context.

This command will display the name of the new _kubectl_ configuration context.
`kubectl config current-context`

The new context name should start with the letters _gke_ and then include your project name, zone, and cluster name.

#### Switch Local kubectl Configs to Legacy Authentiation

This command will display the contents of the _kubectl_ configuration file.
`kubect config view`

You should see three new entries in the output under the _clusters_, _contexts_ and _users_ sections, and the new context should be listed as the _current-context_ value.

Go back to your browser window and open the GCP Console tab.  Navigate to the _Kubernetes engine_ main _Clusters_ page if it's not already open.  You should see your new _gestalt-demo_ cluster listed.  Click on the cluster name to view the cluster details.

In the _Details_ tab, you should see an entry named *Endpoint* with an IP number value.  Click the _Show credentials_ link to the right of the value.

The _Cluster credentials_ dialog should list the _Username_, _Password_ and _Cluster CA certificate_ for your GKE cluster.  The username is always
_admin_, but make a note in case it's something else.  Select the value of the _Password_ field and Copy it into your local clipboard.

_*Pro Tip:*_ This command will print the password, which you can then pipe to `pbcopy` to automagically copy it to the clipboard.
`gcloud container clusters describe [CLUSTER-NAME] | awk '/password:/{print $2}' | pbcopy`

Now open the `~/.kube/config`your favorite text editor.  This is your local _kubectl_ configuration file.  You might want to save a backup copy, just in case.

Find the _user_ entry for your cluster configuration.  It should look something like this.

```
users:
- name: gke_your-project_us-east1-b_gestalt-demo
  user:
    auth-provider:
      config:
        cmd-args: config config-helper --format=json
        cmd-path: /Users/yourname/google-cloud-sdk/bin/gcloud
        expiry-key: '{.credential.token_expiry}'
        token-key: '{.credential.access_token}'
      name: gcp
```

Replace everything under the `user:` line with a _username_ and _password_ using the password value you copied from the cluster details.

```
users:
- name: gke_galacticfog-public_us-east1-b_gestalt-test-install
  user:
    username: admin
    password: [PASSWORD_VALUE]
```

Save the file and close your text editor.

This command will print out some information about the connected cluster.
`kubectl cluster-info`

If your username and password are both correct, and you remembered to check _Enable Legacy Authorization_ when you created the cluster, you should see four or five lines of information about the cluster.  If not, you'll only see the cluster IP address and this will be the last line of output.
`error: You must be logged in to the server (Unauthorized)`

You can try this command to enable _Legacy Authorization_ if you forgot to check the box when you created the cluster.
`gcloud container clusters update gestalt-demo --enable-legacy-authorization`

If you've broken your _kubectl_ configuration file and you forgot to create a backup copy, run this command again to generate a new access token and start over.
`gcloud container clusters get-credentials gestalt-demo`

When you are able to connect and see information about your cluster using the cluster admin username and password, you're ready to install Gestalt!

## Install Gestalt

First, clone the [gestalt-kubernetes-installer project](https://github.com/GalacticFog/gestalt-kubernetes-installer).

The installer scripts are all in the _client_ subdirectory.
`cd gestalt-kubernetest-installer/client`

You'll need to make a few changes to the standard Gestalt install configurations.

### Configure a local PostgreSQL instance and storage

If you don't already have a database instance that Gestalt can use to store its data, you can configure the installer to create and use a new PostgreSQL container as part of the install process.

Open the _gestalt.conf_ file in your favorite text editor and find the _Database Configuration_ section.  It should look something like this:
```
# ------------- Database Configuration --------------------------------------------
# -- To provision an internal database, set provision_internal_database=Yes, then
# -- the other database settings - host, port, credentials - are ignored.
provision_internal_database=No
database_image="postgres:9.6.11"
database_hostname="gestalt-postgresql.gestalt-system.svc.cluster.local"
database_name=postgres

internal_database_pv_storage_class="gp2"
internal_database_pv_storage_size="100Mi"
postgres_persistence_subpath="postgres"
postgres_memory_request=100Mi
postgres_cpu_request=100m
```

In this case, we want to provision a new database, so change the value of the `provision_internal_database` field to *Yes*.

The installer will also try to use the `internal_database_pv_storage_class` to provision a [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) that PostgreSQL will use to store data.  To create the volume on GCP, change the value to _standard_.

The result should look something like this:
```
# ------------- Database Configuration --------------------------------------------
# -- To provision an internal database, set provision_internal_database=Yes, then
# -- the other database settings - host, port, credentials - are ignored.
provision_internal_database=Yes
database_image="postgres"
database_image_tag="9.6.11"
database_hostname="gestalt-postgresql.gestalt-system.svc.cluster.local"
database_name=postgres

internal_database_pv_storage_class="standard"
internal_database_pv_storage_size="100Mi"
postgres_persistence_subpath="postgres"
postgres_memory_request=100Mi
postgres_cpu_request=100m
```

Save the file and close your text editor.

### Configure the Elasticsearch Deployment to Set `vm.max_map_count=262166`

In order to ensure that we set the required vm.max_map_count value for the Elasticsearch server, we need to add an InitController to the elastic Deployment that will run before the elastic container starts up.

Use your favorite text editor to add this *initContainers* entry to the *spec/template/spec* section of the `configmaps/gestalt/templates/elastic` file just before the *containers* entry.
```
      initContainers:
      - name: init-sysctl
        image: busybox:1.27.2
        command:
        - sh
        - -c
        - sysctl -w vm.max_map_count=262166
        securityContext:
          privileged: true
```

Save the file and close your text editor.

### Add a Gestalt Software License

If you don't already have a Gestalt Software License, talk to your sales representative.  Your license is a cryptographically-signed and base-64 encoded sequence of characters which includes a client identifier and an expiration date.  When the expiration date has passed, you'll need to install a new license in order to keep using Gestalt.

TBD - see [gestalt-license](https://gitlab.com/galacticfog/gestalt-license).

### Run the configure.sh script

`./configure.sh`

### Create the `gestalt-system` namespace

`kubectl create namespace gestalt-system`

### Run the stage.sh script

`./stage.sh`

### Run the install.sh script

`./install.sh`

### Verify Gestalt Service Startup

`kubectl -n gestalt-system get pods`

Once you see that the _gestalt-installer_ pod has been created and is in _Running_ state, you can follow the logs with this script.

`./follow-logs.sh`

### Create GCP LoadBalancers to Expose Gestalt UI and Services

TBD
