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


    // we create an unencrypted file locally first, because that way we get the right dependency checking.
    // we don't commit files matching *secrets.json - make sure this is in .gitignore!

    local intermediate_file_name = '%s.secrets.json' % file_name,
    local san_inter = $.sanitize_name(intermediate_file_name),
    local_file+: {
      [san_inter]: {
        content: std.escapeStringBash(std.manifestJsonEx(data, '  ')),
        filename: intermediate_file_name,
      }  
    },
    null_resource+: {
      [$.sanitize_name(file_name)]: {
        triggers: {
          file: '${local_file.%s.content}' % san_inter,
        },
          
        provisioner: {
          'local-exec': {
            command: (
              'echo ${local_file.%s.content}|' % san_inter +
              'sops --encrypt --gcp-kms %s' % key_name  +
              ' --input-type json --output-type json /dev/stdin > %s' % file_name
            )
          },
        },
      },
    },
  },
}
