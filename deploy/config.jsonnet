/*
 Edit this file to configure deployment.
*/

{
  github: {
    user: 'PaulRudin',
    repo: 'stbotolphs',
  },
  
  
  k8s: {

    /* this needs to be a subdomain of a domain you control. 
     atm dns record needs to be updated manually
     */
    root_dns_name: 'stbots.rudin.co.uk', 
    
    flux: {
      /* flux will pull from this github repo to apply latest k8s manifests. (Assumed to be public.) */
      
      git_url: 'git@github.com:PaulRudin/stbotolphs',

      git_path: 'deploy/k8s',
      
      // doesn't actually matter as we're not going to push commits/tags.
      git_email: $.k8s.letsencrypt_email,
    },

    
    /* this will appear on certificate requests to lets encrypt, doesn't
    actually matter, but letencrypt will send expiry warnings */
 
    letsencrypt_email: 'paul@rudin.co.uk',

    // for the django superuser
    django_email: self.letsencrypt_email,

    
  },

  gcloud: {

    // this should be a valid billing account; see a list via: gcloud alpha billing list
    billing_account: '01BAAE-7E5EA5-0DCA2E',

    /* these users will have necessary permissions to deal with the
    project. Probably not strictly necessary, but makes life easier for
    viewing/fettling through the cloud console or the cli.  */
    
    extra_users: ["paul@rudin.co.uk"],


    /* YOU PROBABLY DON'T NEED TO CHANGE ANYTHING BELOW THIS */
    
    // this is the project for the terraform state - it's good to keep it seperate from the project
    // for the resources we actually use to run stuff
    admin_project: "stbotolphs-bootstrap",

    // this is the name of the service account that terraform runs as.
    admin_sa: "stbotolophs-admin",

    // this is the project within which all the resources needed for deploying the software will be created
    project: "stbots",

    // all resources will be created in this region
    region: 'europe-west2',

    // all resources will be created in this zone
    zone: self.region + '-a',


    // the structure matters here, as it's used in the configuration for the database
    local g = self,
    postgres: {
      name: 'master',
      database_version: 'POSTGRES_11',
      region: g.region,
      settings+: {
        tier: 'db-f1-micro',
      },
    },
    
    // doesn't really matter
    cluster_name: self.project,

    // this is the bucket for terraform state
    tfbucket: "%s-tfstate" % self.admin_project,

    // leave this alone unless you're you know what you're doing by changing it
    admin_sa_name: "%s@%s.iam.gserviceaccount.com" % [self.admin_sa, self.admin_project],
    
  },
}
