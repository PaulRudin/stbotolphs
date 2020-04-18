/*
 Edit this file to configure deployment.
*/

{
  gcloud: {

    // this is the project for the terraform state - it's good to keep it seperate from the project
    // for the resources we actually use to run stuff
    admin_project: "stbotolphs-bootstrap",

    // this is the name of the service account that terraform runs as.
    admin_sa: "stbotolophs-admin",

    // bucket in the admin project used for storing terraform state
    tf_bucket: 'terraform/state',

    // this is the project within which all the resources needed for deploying the software will be created
    project: "stbotolphs",


    // this should be a valid billing account; see a list via: gcloud alpha billing list
    billing_account: '01BAAE-7E5EA5-0DCA2E',

    // all resources will be created in this region
    region: 'europe-west2',

    // all resources will be created in this zone
    zone: self.region + '-a',

    // doesn't really matter
    cluster_name: self.project,

    tfbucket: "%s-tfstate" % self.project,

    // leave this alone unless you're sure you know what you're doing.
    admin_sa_name: "%s@%s.iam.gserviceaccount.com" % [self.admin_sa, self.admin_project],

  },
}
