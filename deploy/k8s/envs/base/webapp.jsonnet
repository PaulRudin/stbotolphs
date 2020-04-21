local name = 'webapp';
local port = 8080; //FIXME - what's the app actually listening on?
{
  local tfdata = $.globals.tfdata,
  config:: {
    dbname: 'prod',
    dbpassword: tfdata.postgres.password,
    dbuser: tfdata.postgres.user,
    dbhost: tfdata.postgres.ip,
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
        'secret-generator.v1.mittwald.de/autogenerate': 'django_secret_key',
      },
    },
  },

  deploy: k.Deployment(name) {
    spec+: {
      replicas: 1,
      template+: {
        spec+: {
          local env_data = {
            DJANGO_DANGEROUS_DEBUG: '0',
            DJANGO_DB_ENGINE: 'django.db.backends.postgresql',
            DJANGO_DB_HOST: $.config.dbhost,
            DJANGO_DB_NAME: $.config.dbname,
            DJANGO_DB_USER: $.config.dbuser,
            DJANGO_DB_PASSWORD: $.config.dbpassword,
            DJANGO_DB_PORT: '5432',
            DJANGO_DB_CONN_MAX_AGE: '60',
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
