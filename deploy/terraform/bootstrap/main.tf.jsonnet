local config  = (import '../../config.jsonnet').gcloud;

{
  provider: {
    google: {
      user_project_override: true,
    }
  },

  resource: {
    google_project: {
      [config.admin_project]: {
        name: config.admin_project,
        project_id: config.admin_project,
        billing_account: config.billing_account,
      },
    },

    google_service_account: {
      [config.admin_sa]: {
        project: config.admin_project,
        account_id: config.admin_sa,
      },
    },

    /* the credentials for the provider already establish an owner, we could
     remove that for a little extra security and protection against mistakes, but
     it makes things tricky for manual inpection and fettling */


    google_project_iam_member: {
      owner: {
        project: config.admin_project,
        role: 'roles/owner',
        member: 'serviceAccount:' + config.admin_sa_name,
      },
    },

    google_storage_bucket: {
      [config.tfbucket]: {
        project: config.admin_project,
        name: config.tfbucket,
        location: config.region,
        bucket_policy_only: true,
        versioning: {
          enabled: true,
        },
      },
    },

    google_service_account_key: {
      sa_key: {
        service_account_id: config.admin_sa_name,
      },
    },

    local_file: {
      tfcredentials: {
        content: '${base64decode(google_service_account_key.sa_key.private_key)}',
        filename:  '../main/tfsecrets.json',
      },
    },
  },
}
