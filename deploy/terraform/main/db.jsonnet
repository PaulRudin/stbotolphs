{

  /* database + the networking so that the cluster can talk to the database on
  a private ip address */

  local config = $.config,
  resource+: {
    google_compute_global_address+: {
      default: $.proj_mixin + {
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
    
    google_service_networking_connection+: {
      peer: {
        network: network,
        service: 'servicenetworking.googleapis.com',
        reserved_peering_ranges: ['google-managed-services-default'],
      },
    },
 
    google_sql_database_instance+: {
      [config.postgres.name]: config.postgres + $.proj_mixin + {
        settings+: {
          ip_configuration: {
            private_network: network,
          },
        },
      },
    },

    random_password+: {
      postgres_pw: {
        length: 16,
      },
    },

    local instance = '${google_sql_database_instance.%s.name}' % config.postgres.name,
    google_sql_user+: {
      postgres_su: $.proj_mixin + {
        name: 'postgres',
        password: '${random_password.postgres_pw.result}',
        instance: instance
      },
    },

    google_sql_database+: {
      prod: $.proj_mixin + { instance: instance, name: 'prod' },
      staging: $.proj_mixin + { instance: instance, name: 'staging' },
    },
  },
}
