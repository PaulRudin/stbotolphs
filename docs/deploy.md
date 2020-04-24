# Deployment description

This document describes how to deploy the cms, addressing (most of) the
requirements in [the requirements](./to-our-cloud-architect.md).


There's a bit of bootstrapping, but once that's done *everything* should get
deployed or updated by github workflows or by processes running in the k8s
cluster, so you shouldn't need to do anything except via editing files and
pushing to github.

The app is currently running on https://stbots.rudin.co.uk

The staging version is at https://stbots.rudin.co.uk (it's basically the
same), but you can see that the database  is different as they have different
home pages.

Please do ask if anything is unclear or you run into problems.

Note that git is configured to ignore files matching the pattern
"*secrets.json". Some operations will create such files in the working directory,
make sure you don't commit them. Git safe secrets are in files like
"*secrets.enc.json". Secrets are reencrypted  with kubeseal for consumption by
in-cluster workloads.


## Day to day operations

Once bootstrapping has been done all changes are via git. You can make changes
to your web application code, and these will be deployed automatically via
tagging. The "production" version should be tagged with a tag of the form
"v0.x.y" on master. If you ever decide to migrate to a version like "v1.x.y"
then the file ./deploy/k8s/.flux.yaml should be edited to reflect this (change
should be obvious).

If you want to experiment with pre-production versions then make changes on the
staging branch and push tags that looks like "v0.x.y-z". This will end up being
available on the "staging-" variant of the domain name configured (see
below). Once you're happy with a pre-production version then just merge to
master and tag without the "-z" suffix.  This works because
[flux](https://github.com/fluxcd/flux) runs in the k8s cluster and polls github
for config changes, and the docker registry for newer images.


The staging branch is only used by the automation for the configuration in the
./deploy/k8s/envs/staging directory. The terraform application only
automatically runs from master.


You might get occasional emails from letsencrypt warning that a certificate is
about to expire, but IME they're always automatically replaced before they
expire.


## Bootstrapping

* This should work fine on any widely used linux (I'm using Ubuntu
  20.04). It'll probably work on a Mac or Windows (but untested).

* Merge the PR (or copy its repo to a new repo in your github account if you want
  to keep your existing repo as it).

* Clone your repo locally.

* Everything gets deployed to google cloud, so you'll need an account - which
  can be created from the [gcloud console](https://console.cloud.google.com).

* Paths are relative to the cloned working directory.

* Check necessary tools at the end of this document - install any you don't
  have. `cd deploy && make install_tools` will download the relevant binaries
  and install them in /usr/local/bin.

* Edit the file ./deploy/config.jsonnet. At a minumum you should change:

** `k8s.root_dns_name`
** `k8s.flux.git_url`
** `k8s.letsencrypt_email`
** `gcloud.billing_account`
** `gcloud.extra_users`
** `github.user`
** `github.repo`

Note that deploying this stuff will incur charges with google - that's why the
billing account is necessary.

* Make sure you're authenticated with terraform.

* Cd to ./deploy and run `make tfbootstrap`. This will generate and run
  terraform configuration from the ./deploy/terraform/. Sometimes terraform
  needs a couple of goes, because remotely provisioned resources can take a
  while. This step is never run by a github workflow, it's assume that these
  things won't change.

* Go to the github settings for the repo and create a secret called
  "GOOGLE_KEY" and paste in the contents of
  ./deploy/terraform/main/tfsecrets.json.
  
* Push your changes to github. This should trigger the workflow
  ./.github/workflows/terraform.yaml, which applies the main terraform
  configuration from ./deploy/terraform/main. The first time round it'll
  probably take a while, and may need a couple of goes.
  
  You can also run this step locally by cd'ing to ./deploy and doing `make tfapply`

* Once terraform has done it's thing quite a few resources will have been
  created. You can check this via the gcloud console. All the important stuff
  belongs to the project "stbots" (unless you changed the project name in
  config.jsonnet).
  
* Github will have made some commits (or if you did `make tfapply` locally
  you'll have local changes which you should commit).
  
* Push a tag like "v0.0.1" to the master branch of the repo. This should
  trigger the workflow ./.github/workflows/docker.yaml to build and push a
  docker image to our (newly created) private docker registry.

* Configure email. It seems google don't have their own mechanism for email
  sending that can be configured via terraform (you can on AWS), so you either
  need to use an existing smtp server (presumably the University has one
  available) or use Sendgrid from the google market place (if you do this
  there's a reasonably generous free tier, and the billing comes via
  google). Edit the file ./deploy/k8s/external_secrets.enc.json via sops (DO
  NOT replace with an un-encrypted file). Despite the Sendgrid-centric key
  names, data for any smtp server will do.

* Now cd to ./deploy/k8s and run `make env=base update` and `make env=staging
  update`. These might take a while first time, and initially it'll take a
  little bit of time before the cluster has pulled all the necessary images and
  got going.
  
* Once the load balancer for the ingress controller has been provisioned you
  need to manually update the A record for the name you set for
  `k8s.root_dns_name` to be the public ip address of the load balancer (you can
  see this with `kubectl get -n ingress-nginx svc ingress-nginx -o yaml` and
  look at the status block at the end. It's a shame that this can't be
  automated - on AWS this can be done via annotations on the service, but it
  seems that Google don't have an equivalent.

* There are two versions of flux running, for the staging config and one for
  the default. Once they're running add their deploy keys via the github ui
  project. You can see the keys with `fluxctl --k8s-fwd-ns=flux identity` and
  `fluxctl --k8s-fwd-ns=flux-staging identity`
