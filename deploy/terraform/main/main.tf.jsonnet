local config = (import '../../config.jsonnet').gcloud;
local creds = 'tfsecrets.json';
{
  provider: {
    google: {
      region: config.region,
      credentials: creds,
    },
  }, //provider

  data: {
    google_project: {
      [config.admin_project]: {
        project_id: config.admin_project,
      }
    },
  },
  resource: {

    google_project: {
      [config.project]: {
        provider: 'google',
        name: config.project,
        project_id: config.project,
        billing_account: config.billing_account,
        org_id: '${data.google_project.%s.org_id}' % config.admin_project,
      },
    },

    
    google_project_iam_member: {
      p: { 
        project: config.project,
        role: "roles/owner",
        member: "user:paul@rudin.co.uk",
      },
    },

    local proj_mixin = {
      project: '${google_project.%s.project_id}' % config.project,
    },

    google_project_service: {
      k8s: proj_mixin + {
        service: "container.googleapis.com",
      },
      billing: proj_mixin + {
        service: "cloudbilling.googleapis.com",
      },
    },
    // use the long form to establish the dependency graph

    google_container_cluster: {
      [config.cluster_name]: proj_mixin + {
        name: config.cluster_name,
        location: config.zone,
        remove_default_node_pool: true,
        initial_node_count: 1,
        master_auth: {
          username: '',
          password: '',
          client_certificate_config: {
            issue_client_certificate: false,
          },
        },
      },
    }, // google_container_cluster

    google_container_node_pool: {
      [config.cluster_name + '_primary_nodes']: proj_mixin + {
        name: '%s-k8s-primary-node-pool' % config.cluster_name,
        location: config.zone,
        cluster:  config.cluster_name,
        initial_node_count: 1,
        autoscaling: {
          max_node_count: 5,
          min_node_count: 1,
        },
        node_config: {
          machine_type: 'g1-small',
          metadata: {
            'disable-legacy-endpoints': true,
          },

          oauth_scopes: [
            'https://www.googleapis.com/auth/logging.write',
            'https://www.googleapis.com/auth/monitoring',
            'https://www.googleapis.com/auth/devstorage.read_only',

            # needed for external dns
            'https://www.googleapis.com/auth/ndev.clouddns.readwrite',
          ],
        },
      },
    },
  }, //resource
}
