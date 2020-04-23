{
  local config = $.config,
  resource+: {
    local provider_beta_mix =  {provider: 'google-beta'},

    google_container_cluster+: {
      [config.cluster_name]: provider_beta_mix + $.proj_mixin + {
        name: config.cluster_name,
        location: config.zone,
        remove_default_node_pool: true,
        initial_node_count: 1,
        min_master_version: '1.16',
        master_auth: {
          username: '',
          password: '',
          client_certificate_config: {
            issue_client_certificate: false,
          },
        },

        // vpc native in order to permit private ip communication with
        // postgres etc.
        ip_allocation_policy: {
          // blank - gets chosen for you
          cluster_ipv4_cidr_block: '',
          services_ipv4_cidr_block: '',
        },

        workload_identity_config: {
          identity_namespace: '%s.svc.id.goog' % $.project,
        },
      },
    }, // google_container_cluster

    google_container_node_pool+: {
      [config.cluster_name + '_primary_nodes']: $.proj_mixin + {
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

    // the stuff below here is for workload identity - we're not actually using it atm.

    local sa_name = 'cnrm-system',
    local sa_full_name = '%s@%s.iam.gserviceaccount.com' % [sa_name, $.project],
    google_service_account+: {
      cnrm_system: $.proj_mixin + {
        account_id: sa_name,
      },
    },
    google_project_iam_member+: {
      owner: {
        project: config.project,
        role: 'roles/owner',
        member: 'serviceAccount:%s' % sa_full_name,
      }, 
    },

    // create a binding between the sa and the pre-defined k8s sa
    google_service_account_iam_member+: {
      k8s: {
        service_account_id: '${google_service_account.cnrm_system.id}',
        role: 'roles/iam.workloadIdentityUser',
        member: 'serviceAccount:%s.svc.id.goog[cnrm-system/cnrm-controller-manager]' % $.project,
      },
    },
  },
}
