local base = import '../base/all.jsonnet';

{
  local g = base.globals,
  local namespace = 'staging',
  
  webapp: base.webapp + {
    config+: {
      dbname: 'staging',
      bucket: g.tfdata.staging_cms_bucket_name,
      namespace: 'staging',
      host: 'staging-' + super.host,
      image_update_pattern: 'semver:~0-0'
    },
  },

  local ns_mixin = { metadata+: {namespace: namespace }},
  secrets: base.secrets + {
    [k]+: ns_mixin
    for k in std.objectFields(base.secrets)
  },

  flux: base.flux + {
    namespace: 'flux-staging',
    branch: 'staging',
    git_sync_tag: 'flux-sync-staging',
    git_path: super.git_path + '/envs/staging',
  },
}
