local utils = import '../utils.jsonnet';
{
  config:: (import '../../config.jsonnet').gcloud,
}

+ (import './provider.jsonnet')

+ (import './project.jsonnet')

+ (import './cluster.jsonnet')

+ (import './registry.jsonnet')

+ (import './db.jsonnet')

+ (import './crypto.jsonnet')

+ (import './cms_storage_bucket.jsonnet')

{
  local config = $.config,
  resource+: {

    // this is for data that isn't sensitive
    local_file+: {
      tfdata: {
        content: std.manifestJsonEx({
          registry: 'eu.gcr.io/%s' % $.project,
          
          // this is just names the key - it's not sensitive
          crypto_key: '${google_kms_crypto_key.crypto_key.self_link}',
          
          postgres: {
            ip: '${google_sql_database_instance.%s.private_ip_address}' % config.postgres.name,
            user: 'postgres',
          },
          cms_bucket_name: $.cms_storage_bucket_name,
        }, '  '),
        filename: '../../k8s/tfdata.json',
      },
    },

    null_resource+: {
      sopsdata: {
        //triggers: {always_run: '${timestamp()}'},
        provisioner: {
          
          // this creates a sops encypted file for sensitive data, it depends on sops being present
          'local-exec': {

            local content = std.escapeStringBash(std.manifestJsonEx({
              data: {
                postgres_password: '${random_password.postgres_pw.result}',
                cms_bucket_key_id: '${google_storage_hmac_key.%s.access_id}' % $.cms_storage_bucket_key_name,
                cms_bucket_key_secret: '${google_storage_hmac_key.%s.secret}' % $.cms_storage_bucket_key_name,
              },
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
