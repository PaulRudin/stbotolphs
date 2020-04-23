{
  local config = $.config,
  cms_storage_bucket_name:: '%s-cms' % config.project,
  staging_bucket:: 'staging-%s' % $.cms_storage_bucket_name,
  local buckets = [$.cms_storage_bucket_name, $.staging_bucket],
  cms_storage_bucket_key_name:: '%s-key' % $.cms_storage_bucket_name,

  resource+: {
    google_storage_bucket+: {
      [bucket]: $.proj_mixin + {
        name: bucket,
        location: config.region,
      } for bucket in buckets
    },

    google_storage_bucket_acl+: {
      [bucket]: {
        bucket: bucket,
        predefined_acl: 'publicRead',
      } for bucket in buckets
    },

    google_service_account+:  {
      cms: $.proj_mixin + {
        account_id: 'cms-sa',
      },
    },

    google_storage_bucket_iam_member+: {
      [bucket]: {
        bucket: bucket,
        role: 'roles/storage.admin',
        member: 'serviceAccount:${google_service_account.cms.email}', 
      } for bucket in buckets
    },
    google_storage_hmac_key+: {
      [$.cms_storage_bucket_key_name]: $.proj_mixin + {
        service_account_email: '${google_service_account.cms.email}',
      },
    },
  },
}
