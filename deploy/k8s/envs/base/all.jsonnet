local config = {
  
  cert_manager: import 'cert-manager.jsonnet',
  secretgen: import 'secretgen.jsonnet',
  // global_secret: import 'globalsecrets.sealed.json',
  sealed_secrets_controller: import 'sealed-secrets-controller.jsonnet',
  flux: import 'flux.jsonnet',
  globals:: {
    images:: import 'images.jsonnet',
    root_dns_name:: 'xamaral.com',
    k:: import 'klib.libsonnet',
    env:: std.extVar("env"),
  },
};

config + {
  local s = self, 
  [k]: config[k] + {globals:: s.globals},
  for k in std.objectFields(config)
}
