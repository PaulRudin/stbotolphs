{
  _config:: {
    namespace: 'kube-system',
    image: $.globals.images.secretgen,
  },

  local ns_mixin = { metadata+: {namespace: $._config.namespace }},

  operator: std.native('parseYaml')(importstr 'secretgen/operator.yaml')[0] + ns_mixin + {
    spec+: {template+: {spec+: {containers: [
      super.containers[0] + {
        image: $._config.image,
        command: null,
      }
    ]}}}
  },

  role_binding: std.native('parseYaml')(importstr 'secretgen/role_binding.yaml')[0] + ns_mixin,
  role: std.native('parseYaml')(importstr 'secretgen/role.yaml')[0] + ns_mixin,

  service_account: std.native('parseYaml')(importstr 'secretgen/service_account.yaml')[0] + ns_mixin,

  cluster_role_binding: std.native('parseYaml')(importstr 'secretgen/cluster_role_binding.yaml')[0] + {
    subjects: [super.subjects[0] + {namespace: $._config.namespace}]
  },
}
