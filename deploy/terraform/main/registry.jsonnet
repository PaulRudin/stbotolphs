local utils = import '../utils.jsonnet'; 
{
  resource+: {
    google_container_registry+: {
      registry: $.proj_mixin + {
        location: 'EU',
      },
    },

    google_storage_bucket_iam_member+: {
      [utils.sanitize_name(u)]: {
        bucket: '${google_container_registry.registry.id}',
        role: 'roles/storage.admin',
        member: 'user:%s' % u,
      } for u in $.config.extra_users
    },
  },
}
