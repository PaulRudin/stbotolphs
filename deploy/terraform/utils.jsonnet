{
  sanitize_name: function(s) (
    std.strReplace(
      std.strReplace(
        std.strReplace(s, '.', '_'),
        '@', '_'),
      '/', '_')
  ),

  sops_out: function(file_name, key_name, data) {
    // create a sops encrypted json file for given content and key

    null_resource+: {
      [$.sanitize_name(file_name)]: {
        provisioner: {
          'local-exec': {
            local content = std.escapeStringBash(std.manifestJsonEx(data, '  ')),
            command: (
              'echo -n %s |' % content +
              'sops --encrypt --gcp-kms %s' % key_name  +
              ' --input-type json --output-type json /dev/stdin > %s' % file_name
            )
          },
        },
      },
    },
  },
}
