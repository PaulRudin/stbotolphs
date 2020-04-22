local name = 'webapp';
local port = 8080;
{
  local g = $.globals,
  config:: {
    dbname: 'prod',
    dbuser: g.tfdata.postgres.user,
    dbhost: g.tfdata.postgres.ip,
    bucket: g.tfdata.cms_bucket_name,
    region: g.config.gcloud.region,
  },
  local k = $.globals.k,
  svc: k.Service(name) {
    target_pod: $.deploy.spec.template,
  },

  ingress: k.Ingress(name) + k.mixins.TlsIngress + {
    spec+: {
      rules: [{
        host: $.globals.root_dns_name,
        http: {
          paths: [
            {
              path: '/',
              backend: { serviceName: name, servicePort: port},
            },
          ],
        },
      }],
    },
  }, //ingress

  django_secret: k.Secret(name) {
    metadata+: {
      annotations+: {
        'secret-generator.v1.mittwald.de/autogenerate': 'django_secret_key,admin_password',
      },
    },
  },

  deploy: k.Deployment(name) {
    spec+: {
      replicas: 1,
      template+: {
        spec+: {
          local ext_envmap = {
            DJANGO_EMAIL_HOST_USER: 'sendgrid_user',
            DJANGO_EMAIL_HOST_PASSWORD: 'sendgrid_password',
            DJANGO_EMAIL_PORT: 'sendgrid_port',
            DJANGO_EMAIL_HOST: 'sendgrid_host',
          },

          local tfs_envmap = {
            
            DJANGO_AWS_ACCESS_KEY_ID: 'cms_bucket_key_id',
            DJANGO_AWS_SECRET_ACCESS_KEY: 'cms_bucket_key_secret',
            DJANGO_DB_PASSWORD: 'postgres_password',
          },
          
          local env_data = {
            DJANGO_USE_AWS: '1',
            DJANGO_AWS_LOCATION: '',
            DJANGO_AWS_S3_REGION_NAME: $.config.region,
            // not sure why host and endpoint are both needed
            DJANGO_AWS_S3_HOST: 'storage.googleapis.com',
            DJANGO_AWS_S3_ENDPOINT_URL: 'https://storage.googleapis.com/',
            DJANGO_AWS_STORAGE_BUCKET_NAME: $.config.bucket,
            DJANGO_DB_ENGINE: 'django.db.backends.postgresql',
            DJANGO_DB_HOST: $.config.dbhost,
            DJANGO_DB_NAME: $.config.dbname,
            DJANGO_DB_USER: $.config.dbuser,
            DJANGO_DB_PORT: '5432',
            DJANGO_DB_CONN_MAX_AGE: '60',
          } + {
            [k]: {
              secretKeyRef: {
                name: 'external-secrets',
                key: ext_envmap[k],
              },
            } for k in std.objectFields(ext_envmap)
          } + {
            [k]: {
              secretKeyRef: {
                name: 'tfsecrets',
                key: tfs_envmap[k],
              },
            } for k in std.objectFields(tfs_envmap)
          } + {
            DJANGO_SECRET_KEY: {
              secretKeyRef: {
                name: name,
                key: 'django_secret_key',
              },
            },
          },

          initContainers: [
            k.Container('migrate') {
              image: $.globals.images.webapp,
              command: ['./manage.py', 'migrate'],
              env_+: env_data,
            },
            k.Container('setpw') {
              image: $.globals.images.webapp,
              // FIXME: this sets initially, but ignores error so that we don't try to create twice
              command: [
                'sh',
                '-c',
                './manage.py createsuperuser --no-input --username=admin --email=%s || true' % $.globals.config.k8s.django_email
              ],
              env_+: env_data + {
                DJANGO_SUPERUSER_PASSWORD: {
                  secretKeyRef: {
                    name: name,
                    key: 'admin_password'
                  },
                },
              },
            },
          ],

          containers_+: {
            default: k.Container('default') {
              image: $.globals.images.webapp,
              resources: {
                // tune this once we have some data about actual usage
                requests: {cpu: '100m', memory: '100Mi'}, 
              },
              ports: [{containerPort: port}],
              env_+: env_data,
            },
          },
        },
      },
    },
  },
}
