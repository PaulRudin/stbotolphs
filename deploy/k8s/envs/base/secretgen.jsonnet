local name = 'secretgen';
local namespace = 'kube-system';
{
  local k = $.globals.k,

  deployment: k.Deployment(name) {
    metadata+: {
      namespace: namespace,
    },
    spec+: {
      replicas: 1,
      template+: {
        spec+: {
          serviceAccountName: name,
          containers_: {
            secretgen: {
              image: $.globals.images.secret_gen,
              command: ['/kubernetes-secret-generator'],
              // 32 because oauth2-proxy cookie secret can only be certain lengths
              args: ['-logtostderr', '-all-namespaces', '-regenerate-insecure', '-secret-length=32'],
            },
          },
        },
      },
    },
  },

  clusterRole: k.ClusterRole(name) {
    rules: [
      {
        apiGroups: [''],
        resources: ['secrets'],
        verbs: ['get', 'watch', 'list', 'update'],
      },
    ],
  },

  crb: k.ClusterRoleBinding(name) {
    roleRef: {
      kind: 'ClusterRole',
      name: name,
      apiGroup: 'rbac.authorization.k8s.io',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: name,
        namespace: namespace,
      },
    ],
  },

  sa: k.ServiceAccount(name) {
    metadata+: {
      namespace: namespace,
    },
  },
}
