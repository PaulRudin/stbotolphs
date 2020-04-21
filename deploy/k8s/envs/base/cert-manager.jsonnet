// just use the vendor distributed yaml

{
  cert_manager: std.native('parseYaml')(importstr './vendor/cert-manager.yaml'),

  local k = $.globals.k,
  local s = self,

  local issuer_spec = {
    local spec = self,
    name:: error 'set name',
    acme: {
      email: $.globals.config.k8s.letsencrypt_email,
      privateKeySecretRef: {
        name: spec.name,
      }, 
      server: 'https://acme-v02.api.letsencrypt.org/directory',
      solvers: [{
        http01: {
          ingress: {
            class: 'nginx',
          },
        },
      }],
    },
  },

  local prod_name = 'letsencrypt-prod',
  letsencrypt_prod: k.crds.ClusterIssuer(prod_name) + {
    spec: issuer_spec + {name: prod_name}
  },

  local staging_name = 'letsencrypt-staging',
  letsencrypt_staging: k.crds.ClusterIssuer(staging_name) + {
    spec: issuer_spec + {
      name: staging_name,
      acme+: {server: 'https://acme-staging-v02.api.letsencrypt.org/directory'},
    },
  },
}
