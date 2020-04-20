(import 'kube.libsonnet') {

  local t = self,
  crds: {
    Elasticsearch(name): $._Object(
      'elasticsearch.k8s.elastic.co/v1', 'Elasticsearch', name,
    ) +  {
      spec: {
        version: '7.6.0',
        nodeSets: [{
          name: 'default',
          count: 1,
          config: {
            node: {
              master: true,
              data: true,
              ingest: true,
              store: {allow_mmap: false},
            },
          },
        }],
      },
    }, // elastic
    Kibana(name): $._Object(
      'kibana.k8s.elastic.co/v1', 'Kibana', name
    ) + {
      spec+: {
        // TODO - consist versioning elastic, kibana and relevant CRDs
        version: '7.6.1',
        count: 1,
        http: {

          /* note that we're doing tls through the ingress controller, so we
           don't really need another layer of tls here, be careful if your
           setup is different - you could end up with an way to avoid https
           altogether */
          tls: { selfSignedCertificate: {disabled: true}}
        },
          
        elasticsearchRef: {

          // TODO - refactor so that the name of the elasticsearch instances
          // and this reference are in sync

          name: 'elastic',
        }
      }  
    }
  }, // crds

  mixins: {

    GcsPlugin: {
      // adds an init container for installing the gcs plugin to pods of an Elastic object
      local podTemplateMixin = {
        podTemplate+: {
          spec+: {
            initContainers+: [{
              name: 'install-gcs-plugin',
              command: ['sh', '-c', 'bin/elasticsearch-plugin install --batch repository-gcs'], 
            }],
          },
        },
      },

      spec+: {
        nodeSets: [
          n + podTemplateMixin
          for n in super.nodeSets
        ],
      },
    }, // GcsPlugin
 
    TlsIngress: {
      local s = self,
      metadata+: {
        annotations+: {
          "kubernetes.io/ingress.class": "nginx",
          "cert-manager.io/cluster-issuer": "letsencrypt-prod",
          "cert-manager.io/acme-challenge-type": "http01",
        },
      },
      spec+: {
        tls+: [
          {
            hosts: std.set([rule.host for rule in s.spec.rules]),
            secretName: '%s-tls-secret' % s.metadata.name,
          },
        ],
      },
    },
  },
}
