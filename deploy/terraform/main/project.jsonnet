local utils = import '../utils.jsonnet';
{
  local config = $.config,
  project:: '${google_project.%s.project_id}' % config.project,
  proj_mixin:: {
    project: $.project,
  },


  data+: {
    google_project+: {
      [config.admin_project]: {
        project_id: config.admin_project,
      },
      [config.project]: {
        project_id: config.project,
      },
    },
  },

  resource+: {

    google_project+: {
      [config.project]: {
        provider: 'google',
        name: config.project,
        project_id: config.project,
        billing_account: config.billing_account,
        org_id: '${data.google_project.%s.org_id}' % config.admin_project,
      },
    },
  
    google_project_iam_member+: {
      [utils.sanitize_name(u)]: { 
        project: config.project,
        role: "roles/owner",
        member: 'user:%s' % u,
      } for u in config.extra_users
    },

    google_project_service+: {
      [utils.sanitize_name(s)]: $.proj_mixin + {service: s}
      for s in [
        "container.googleapis.com",
        "cloudbilling.googleapis.com",
        "servicenetworking.googleapis.com",
        "cloudkms.googleapis.com",
      ]
    },
  },
}
