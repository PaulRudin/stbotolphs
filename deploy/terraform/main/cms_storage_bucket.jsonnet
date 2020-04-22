{
  local config = $.config,
  cms_storage_bucket_name:: '%s-cms' % config.project,
  cms_storage_bucket_key_name:: '%s-key' % $.cms_storage_bucket_name,

  resource+: {
    google_storage_bucket+: {
      [$.cms_storage_bucket_name]: $.proj_mixin + {
        name: $.cms_storage_bucket_name,
        location: config.region,
      },
    },

    google_storage_bucket_acl+: {
      [$.cms_storage_bucket_name]: {
        bucket: $.cms_storage_bucket_name,
        predefined_acl: 'publicRead',
      },
    },

    google_service_account+:  {
      cms: $.proj_mixin + {
        account_id: 'cms-sa',
      },
    },

    google_storage_bucket_iam_member+: {
      cms_sa: {
        bucket: $.cms_storage_bucket_name,
        role: 'roles/storage.admin',
        member: 'serviceAccount:${google_service_account.cms.email}', 
      }
    },
    google_storage_hmac_key+: {
      [$.cms_storage_bucket_key_name]: $.proj_mixin + {
        service_account_email: '${google_service_account.cms.email}',
      },
    },
  },
}
