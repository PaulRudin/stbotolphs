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

  local provider_beta_mix = {provider: 'google-beta'},

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


    local project = '${google_project.%s.project_id}' % config.project,
    local proj_mixin = {
      project: project,
    },

    google_project_service: {
      //FIXME: refactor
      k8s: proj_mixin + {
        service: "container.googleapis.com",
      },
      billing: proj_mixin + {
        service: "cloudbilling.googleapis.com",
      },
      networking: proj_mixin + {
        service: "servicenetworking.googleapis.com",
      },
      kms: proj_mixin + {
        service: "cloudkms.googleapis.com",
      }
    },
    // use the long form to establish the dependency graph

    google_container_cluster: {
      [config.cluster_name]: provider_beta_mix + proj_mixin + {
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

        workload_identity_config: {
          identity_namespace: '%s.svc.id.goog' % project,
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

    local sa_name = 'cnrm-system',
    local sa_full_name = '%s@%s.iam.gserviceaccount.com' % [sa_name, project],
    google_service_account: {
      cnrm_system: {
        project: project,
        account_id: sa_name,
      },
    },

    // give the sa owner perms on the project
    local roles = {
      owner: 'roles/owner',
    },
    google_project_iam_member: {

      [utils.sanitize_name(u)]: { 
        project: config.project,
        role: "roles/owner",
        member: 'user:%s' % u,
      } for u in config.extra_users
    } + {
      [k]: {
        project: config.project,
        role: roles[k],
        member: 'serviceAccount:%s' % sa_full_name,
      } for k in std.objectFields(roles)
    },

    // create a binding between the sa and the pre-defined k8s sa
    google_service_account_iam_member: {
      k8s: {
        service_account_id: '${google_service_account.cnrm_system.id}',
        role: 'roles/iam.workloadIdentityUser',
        member: 'serviceAccount:%s.svc.id.goog[cnrm-system/cnrm-controller-manager]' % project,
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


    google_kms_key_ring: {
      key_ring: proj_mixin + {
        name: 'key_ring',
        location: config.region,
      }
    },

    google_kms_crypto_key: {
      crypto_key: {
        name: 'crypto_key',
        key_ring: '${google_kms_key_ring.key_ring.self_link}'
      },
    }, 
    
    // this is for data that isn't sensitive
    local_file: {
      tfdata: {
        content: std.manifestJsonEx({
          registry: 'eu.gcr.io/%s' % project,
          
          // this is just names the key name - it's not sensitive
          crypto_key: '${google_kms_crypto_key.crypto_key.self_link}',

          postgres: {
            ip: '${google_sql_database_instance.%s.private_ip_address}' % config.postgres.name,
            user: 'postgres',
          },
        }, '  '),
        filename: '../../k8s/tfdata.json',
      },
    },

    null_resource: {
      sopsdata: {
        //triggers: {always_run: '${timestamp()}'},
        provisioner: {
          
          // this creates a sops encypted file for sensitive data, it depends on sops being present
          'local-exec': {

            local content = std.escapeStringBash(std.manifestJsonEx({
              data: {postgres_password: '${random_password.postgres_pw.result}'},
              name: 'tfsecrets',
              
            }, '  ')),
            command: (
              'echo -n %s |' % content +
              'sops --encrypt --gcp-kms ${google_kms_crypto_key.crypto_key.self_link}' +
              ' --input-type json --output-type json /dev/stdin > ../../k8s/tfsecrets.enc.json'
            ),
          },
        },
      },
    },

      
    
  }, //resource
}
