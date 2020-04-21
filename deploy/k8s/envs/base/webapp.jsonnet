local name = 'webapp';
local port = 8080;
{
  local g = $.globals,
  config:: {
    dbname: 'prod',
    dbpassword: g.tfsecrets.postgres_password,
    dbuser: g.tfdata.postgres.user,
    dbhost: g.tfdata.postgres.ip,
    mail_user: g.extsecrets.sendgrid.user,
    mail_password: g.extsecrets.sendgrid.password,
    mail_host: g.extsecrets.sendgrid.host,
    mail_port: g.extsecrets.sendgrid.port,
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
          local env_data = {
            DJANGO_DB_ENGINE: 'django.db.backends.postgresql',
            DJANGO_DB_HOST: $.config.dbhost,
            DJANGO_DB_NAME: $.config.dbname,
            DJANGO_DB_USER: $.config.dbuser,
            DJANGO_DB_PASSWORD: $.config.dbpassword,
            DJANGO_DB_PORT: '5432',
            DJANGO_DB_CONN_MAX_AGE: '60',

            DJANGO_EMAIL_HOST_USER: $.config.mail_user,
            DJANGO_EMAIL_HOST_PASSWORD: $.config.mail_password,
            DJANGO_EMAIL_PORT: $.config.mail_port,
            DJANGO_EMAIL_HOST: $.config.mail_host,



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
