{
  config:: (import '../config.jsonnet').gcloud + {creds_file: 'tfsecrets.json'},

  provider: {
    google: {
      project: $.config.project,
      region: $.config.region,
      credentials: $.config.creds_file,
    },
  }, //provider

  resource: {

    google_project: {
      [$.config.project]: {
        name: $.config.project,
        project_id: $.config.project,
      },
    },

    google_container_cluster: {
      [$.config.cluster_name]: {
        name: $.config.cluster_name,
        location: $.config.zone,
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
      [$.config.cluster_name + '_primary_nodes']: {
        name: '%s-k8s-primary-node-pool' % $.config.cluster_name,
        location: $.config.zone,
        cluster: '${google_container_cluster.primary.name}',

        autoscaling: {
          max_node_count: 5,
          min_node_count: 1,
        },
        node_config: {
          // it's probably worth doing a little bit of monitoring and analysis estimate the best kind of machines.
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
