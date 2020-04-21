local config = {

  webapp: import 'webapp.jsonnet',  

  ingress_controller: import 'nginx-ingress-controller.jsonnet',

  cert_manager: import 'cert-manager.jsonnet', // avoid vendor specific tie-in.
  
  secretgen: import 'secretgen.jsonnet',

  //global_secret: import 'globalsecrets.sealed.json',

  sealed_secrets_controller: import 'sealed-secrets-controller.jsonnet',

  flux: import 'flux.jsonnet',

  globals:: {
    images:: import 'images.jsonnet',
    root_dns_name:: 'stbots.rudin.co.uk', // atm dns record needs to be updated manually
    k:: import 'klib.libsonnet',
    env:: std.extVar("env"),
    tfdata:: import '../../../tfsecrets.json',
    config:: import '../../../config.jsonnet',
  },
};

config + {
  local s = self, 
  [k]: config[k] + {globals:: s.globals},
  for k in std.objectFields(config)
}
