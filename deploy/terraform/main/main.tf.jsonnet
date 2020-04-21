local config = (import '../../config.jsonnet').gcloud;
local creds = 'tfsecrets.json';
local utils = import '../utils.jsonnet';
{
  provider: {
    "google-beta": {
      region: config.region,
      credentials: creds,
      version: '~> 3.17',
    },
    "local": {
      version: '~> 1.4',
    },
    random: {
      version: '~> 2.2',
    },
  }, //provider

  data: {
    google_project: {
      [config.admin_project]: {
        project_id: config.admin_project,
      },
      [config.project]: {
        project_id: config.project,
      },
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
      [utils.sanitize_name(u)]: { 
        project: config.project,
        role: "roles/owner",
        member: 'user:%s' % u,
      } for u in config.extra_users
    },

    local project = '${google_project.%s.project_id}' % config.project,
    local proj_mixin = {
      project: project,
    },

    google_project_service: {
      k8s: proj_mixin + {
        service: "container.googleapis.com",
      },
      billing: proj_mixin + {
        service: "cloudbilling.googleapis.com",
      },
      networking: proj_mixin + {
        service: "servicenetworking.googleapis.com",
      },
    },
    // use the long form to establish the dependency graph

    google_container_cluster: {
      [config.cluster_name]: proj_mixin + {
        name: config.cluster_name,
        location: config.zone,
        remove_default_node_pool: true,
        initial_node_count: 1,
        min_master_version: '1.15',
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


    google_container_registry: {
      registry: proj_mixin + {
        location: 'EU',
      },
    },

    google_storage_bucket_iam_member: {
      [utils.sanitize_name(u)]: {
        bucket: '${google_container_registry.registry.id}',
        role: 'roles/storage.admin',
        member: 'user:%s' % u,
      } for u in config.extra_users
    },

    google_compute_global_address: {
      default: proj_mixin + {
        name: 'google-managed-services-default',
        address_type: 'INTERNAL',
        prefix_length: 16,
        purpose: "VPC_PEERING",
        network: "default",
      }
    },

    local network = (
      'https://compute.googleapis.com/compute/v1/projects/%s/global/networks/default' % config.project
    ),
    
    google_service_networking_connection: {
      peer: {
        network: network,
        service: 'servicenetworking.googleapis.com',
        reserved_peering_ranges: ['google-managed-services-default'],
      },
    },
 
    google_sql_database_instance: {
      [config.postgres.name]: config.postgres + proj_mixin + {
        settings+: {
          ip_configuration: {
            private_network: network,
          },
        },
      },
    },

    random_password: {
      postgres_pw: {
        length: 16,
      },
    },

    local instance = '${google_sql_database_instance.%s.name}' % config.postgres.name,
    google_sql_user: {
      postgres_su: proj_mixin + {
        name: 'postgres',
        password: '${random_password.postgres_pw.result}',
        instance: instance
      },
    },

    google_sql_database: {
      prod: proj_mixin + { instance: instance, name: 'prod' },
      staging: proj_mixin + { instance: instance, name: 'staging' },
    },

    /* this is stuff useful outside of terraform - note that we use
       *secrets.json so that git-crypt will encrypt. Not everything is actually
       secret, but it doesn't matter.  */
    
    local_file: {
      tfdata: {
        content: std.manifestJsonEx({
          registry: 'eu.gcr.io/%s' % project,
          postgres: {
            ip: '${google_sql_database_instance.%s.private_ip_address}' % config.postgres.name,
            user: 'postgres',
            password: '${random_password.postgres_pw.result}',
          },
        }, '  '),
        filename: '../../tfsecrets.json',
      },
    },
  }, //resource
}
