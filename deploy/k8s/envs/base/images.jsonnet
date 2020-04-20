{
  global:: {
    docker_registry: 'eu.gcr.io/xamaral/',
  },

  static_web: '%(docker_registry)sstatic-web:latest' % $.global,
  // comments: 'registry.gitlab.com/commento/commento:v1.7.0',
  cert_manager: 'bitnami/cert-manager:0.13.1',
  secret_gen: 'quay.io/mittwald/kubernetes-secret-generator:latest',
  // postgres: 'postgres:11.4',
  k8s_sso: 'xamaral/k8s-sso:latest',
  flux: 'xamaral/fluxkcfg:cc94941',
  flux_memcached: 'memcached:1.5.15',
  echo: 'xamaral/echo',
}
