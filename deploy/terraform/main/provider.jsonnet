{
  local config = $.config,
  
  provider+: {
    "google-beta": {
      region: config.region,
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
