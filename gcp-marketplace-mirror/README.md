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


## Install Gestalt

Follow the directions at [gestalt-kubernetes-installer project](https://github.com/GalacticFog/gestalt-kubernetes-installer).

### Verify Gestalt Service Startup

`kubectl -n gestalt-system get pods`

Once you see that the _gestalt-installer_ pod has been created and is in _Running_ state, you can follow the logs with this script.

`./follow-logs.sh`

### Create GCP LoadBalancers to Expose Gestalt UI and Services

TBD
