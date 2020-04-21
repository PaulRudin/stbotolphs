(import 'kube.libsonnet') {

  crds: {
    ClusterIssuer(name): $._Object('cert-manager.io/v1alpha2', 'ClusterIssuer', name),
  },
  mixins: {
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
