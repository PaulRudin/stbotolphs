local config  = (import '../../config.jsonnet').gcloud;

{
  provider: {
    google: {
    }
  },
  data: {
    google_project: {
      [config.admin_project]: {
        project_id: config.admin_project,
      }
    },
  },

  local org_id = '${data.google_project.%s.org_id}' % config.admin_project,
 
  resource: {
    google_project: {
      [config.admin_project]: {
        name: config.admin_project,
        project_id: config.admin_project,
        billing_account: config.billing_account,
        org_id: org_id,
      },
    },

    local services = [
      "cloudresourcemanager.googleapis.com",
      "serviceusage.googleapis.com",
      "cloudbilling.googleapis.com",
      "iam.googleapis.com",
      "cloudapis.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
    ],

    /* note that these sometime fail on newly created/modified projects
     just retry after a minute */
    google_project_service: {
      [std.strReplace(s, '.', '_')]: {
        project: config.admin_project,
        service: s,
        depends_on: ['google_project.%s' % config.admin_project],
      }
      for s in services
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

    local roles = {
      owner: 'roles/owner',
    },
    google_project_iam_member: {
      [k]: {
        project: config.admin_project,
        role: roles[k],
        member: 'serviceAccount:' + config.admin_sa_name,
      } for k in std.objectFields(roles)
    },

    // seems that the project creator role is at the organization level
    google_organization_iam_member: {
      creator: {
        org_id: org_id,
        role: 'roles/resourcemanager.projectCreator',
        member: 'serviceAccount:' + config.admin_sa_name,
      },
      billing_admin: {
        org_id: org_id,
        role: "roles/billing.admin",
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
