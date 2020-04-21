{
  // Use the yaml provoded with the distribution
  mandatory: std.native('parseYaml')(importstr './vendor/nginx-mandatory.yaml'),
  gke: std.native('parseYaml')(importstr './vendor/nginx-gke.yaml'),
}
