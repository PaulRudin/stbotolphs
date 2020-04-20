// just use the vendor distributed yaml

{cert_manager: 
  std.native('parseYaml')(importstr './vendor/cert-manager.yaml')
}
