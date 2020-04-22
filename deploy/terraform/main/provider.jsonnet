local creds = 'tfsecrets.json';
{
  local config = $.config,
  provider+: {
    "google-beta": {
      region: config.region,
      credentials: creds,
      version: '~> 3.17',
    },
    "local": {
      version: '~> 1.4',
    },
    random: {
      version: '~> 2.2',
    },
  }, //provider
}
