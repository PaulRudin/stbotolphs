{
  config:: (import '../config.jsonnet').gcloud + {creds_file: 'tfsecrets.json'},
  terraform: {
    backend: {
      gcs: {
        bucket: $.config.admin_project,
        prefix: $.config.tf_bucket,
        credentials: $.config.creds_file,
      },
    },
  },
}
