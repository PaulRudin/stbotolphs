local config = {

  webapp: import 'webapp.jsonnet',  

  ingress_controller: import 'nginx-ingress-controller.jsonnet',

  cert_manager: import 'cert-manager.jsonnet', // avoid vendor specific tie-in.
  
  secretgen: import 'secretgen.jsonnet',

  secrets: {
    external: import 'external-secrets.sealed.json',
    tf: import 'tfsecrets.sealed.json',
  },

  sealed_secrets_controller: import 'sealed-secrets-controller.jsonnet',

  flux: import 'flux.jsonnet',

  //gcloud: import 'gcloud-id.jsonnet',
  
  globals:: {
    images:: import 'images.jsonnet',
    root_dns_name:: 'stbots.rudin.co.uk', // atm dns record needs to be updated manually
    k:: import 'klib.libsonnet',
    env:: std.extVar("env"),
    tfdata:: import '../../tfdata.json',
    config:: import '../../../config.jsonnet',
  },
};

config + {
  local s = self, 
  [k]: config[k] + {globals:: s.globals},
  for k in std.objectFields(config)
}
