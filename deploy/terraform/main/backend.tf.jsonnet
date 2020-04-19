local config = (import '../../config.jsonnet').gcloud;
local creds = 'tfsecrets.json';
{
  terraform: {
    backend: {
      gcs: {
        bucket: config.tfbucket,
        credentials: creds,
      },
    },
  },
}
