local tfdata = import '../../tfdata.json';
{
  postgres: 'postgres:11.4',
  webapp: '%s/webapp:latest' % tfdata.registry,
  cert_manager: 'bitnami/cert-manager:0.13.1',
  flux: 'xamaral/fluxkcfg:0.0.6',
  flux_memcached: 'memcached:1.5.15',
  secretgen: 'quay.io/mittwald/kubernetes-secret-generator:v3.0.2',
}
